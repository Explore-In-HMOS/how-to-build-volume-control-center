import { audio } from '@kit.AudioKit';
import { common } from '@kit.AbilityKit';
import { Logger } from '../common/Logger';
import { PermissionHelper } from '../common/PermissionHelper';
import { LoopbackMonitorState } from '../model/LoopbackMonitorState';

/**
 * Manages optional hardware audio loopback monitor behavior.
 *
 * <p>Loopback support is device-dependent, so every public operation updates
 * {@link LoopbackMonitorState} and logs enough detail for real-watch testing.
 * The page never touches the platform loopback object directly.</p>
 */
export class LoopbackMonitorService {
  private streamManager: audio.AudioStreamManager;
  private loopback?: audio.AudioLoopback;
  private statusCallback?: (status: audio.AudioLoopbackStatus) => void;

  /**
   * Creates the monitor service from the shared audio manager.
   *
   * @param audioManager Platform audio manager used to access stream and loopback APIs.
   */
  constructor(audioManager: audio.AudioManager) {
    this.streamManager = audioManager.getStreamManager();
    Logger.monitor('stream manager ready');
  }

  /**
   * Checks whether hardware audio loopback is supported on this device.
   *
   * @param state Current monitor state to update.
   * @returns Updated state with support and status text populated.
   */
  async checkSupport(state: LoopbackMonitorState): Promise<LoopbackMonitorState> {
    try {
      const supported = this.streamManager.isAudioLoopbackSupported(audio.AudioLoopbackMode.HARDWARE);
      state.isSupported = supported;
      state.statusText = supported ? 'Ready' : 'Monitor Mode is not supported on this device.';
      Logger.monitor('support checked', `supported=${supported}`);
    } catch (err) {
      Logger.failure('MONITOR', 'support check failed', err);
      state.isSupported = false;
      state.statusText = 'Monitor Mode is not supported on this device.';
    }
    return state;
  }

  /**
   * Enables hardware loopback monitor mode after permission and support checks.
   *
   * @param context Ability context used for microphone permission requests.
   * @param state Current monitor state to update.
   * @returns Updated monitor state after the enable attempt.
   */
  async enableMonitor(context: common.UIAbilityContext, state: LoopbackMonitorState): Promise<LoopbackMonitorState> {
    Logger.monitor('enable requested',
      `supported=${state.isSupported}, hasPermission=${state.hasPermission}, volume=${state.monitorVolume}`);
    if (!state.isSupported) {
      state.statusText = 'Monitor Mode is not supported on this device.';
      Logger.monitor('enable skipped', 'reason=unsupported');
      return state;
    }

    if (!state.hasPermission) {
      state.hasPermission = await PermissionHelper.requestMicrophone(context);
      if (!state.hasPermission) {
        state.statusText = 'Microphone permission is required for Monitor Mode.';
        Logger.monitor('enable skipped', 'reason=permission_denied');
        return state;
      }
    }

    try {
      if (this.loopback === undefined) {
        this.loopback = await audio.createAudioLoopback(audio.AudioLoopbackMode.HARDWARE);
        state.isCreated = true;
        Logger.monitor('loopback created');
      }
      await this.loopback.setVolume(state.monitorVolume / 100);
      state.isEnabled = await this.loopback.enable(true);
      state.statusText = state.isEnabled ? 'Monitoring on' : this.statusText(await this.loopback.getStatus());
      Logger.monitor('enable finished', `enabled=${state.isEnabled}, status=${state.statusText}`);
    } catch (err) {
      Logger.failure('MONITOR', 'enable failed', err);
      state.isEnabled = false;
      state.statusText = 'Microphone permission is required for Monitor Mode.';
    }
    return state;
  }

  /**
   * Disables hardware loopback monitor mode when it is active.
   *
   * @param state Current monitor state to update.
   * @returns Updated monitor state after the disable attempt.
   */
  async disableMonitor(state: LoopbackMonitorState): Promise<LoopbackMonitorState> {
    Logger.monitor('disable requested', `enabled=${state.isEnabled}`);
    try {
      if (this.loopback !== undefined) {
        await this.loopback.enable(false);
      }
      state.isEnabled = false;
      state.statusText = state.isSupported ? 'Monitoring off' : 'Monitor Mode is not supported on this device.';
      Logger.monitor('disable finished', `status=${state.statusText}`);
    } catch (err) {
      Logger.failure('MONITOR', 'disable failed', err);
      state.statusText = 'Error';
    }
    return state;
  }

  /**
   * Updates the monitor loopback output volume.
   *
   * @param state Current monitor state to mutate.
   * @param volume New monitor volume percentage from 0 to 100.
   * @returns Updated monitor state.
   */
  async setMonitorVolume(state: LoopbackMonitorState, volume: number): Promise<LoopbackMonitorState> {
    state.monitorVolume = volume;
    Logger.monitor('volume requested', `volume=${volume}`);
    if (this.loopback !== undefined) {
      try {
        await this.loopback.setVolume(volume / 100);
        Logger.monitor('volume updated', `volume=${volume}`);
      } catch (err) {
        Logger.failure('MONITOR', 'volume update failed', err);
      }
    }
    return state;
  }

  /**
   * Subscribes to loopback status changes when a loopback object exists.
   *
   * @param onChange Callback invoked with the platform loopback status.
   */
  observeStatus(onChange: (status: audio.AudioLoopbackStatus) => void): void {
    if (this.loopback === undefined) {
      return;
    }
    try {
      if (this.statusCallback !== undefined) {
        this.loopback.off('statusChange', this.statusCallback);
      }
      this.statusCallback = onChange;
      this.loopback.on('statusChange', onChange);
      Logger.monitor('status listener subscribed');
    } catch (err) {
      Logger.failure('MONITOR', 'status subscription failed', err);
    }
  }

  /**
   * Releases monitor resources during page teardown.
   */
  async release(): Promise<void> {
    if (this.loopback === undefined) {
      return;
    }

    try {
      if (this.statusCallback !== undefined) {
        this.loopback.off('statusChange', this.statusCallback);
        Logger.monitor('status listener removed');
      }
      await this.loopback.enable(false);
      Logger.monitor('loopback released');
    } catch (err) {
      Logger.failure('MONITOR', 'release cleanup failed', err);
    }
    this.loopback = undefined;
    this.statusCallback = undefined;
  }

  /**
   * Maps platform loopback status values to user-facing status text.
   *
   * @param status Platform loopback status.
   * @returns Short status message for the monitor card.
   */
  statusText(status: audio.AudioLoopbackStatus): string {
    if (status === audio.AudioLoopbackStatus.AVAILABLE_RUNNING) {
      return 'Monitoring on';
    }
    if (status === audio.AudioLoopbackStatus.UNAVAILABLE_DEVICE) {
      return 'Monitor Mode is not supported on this device.';
    }
    if (status === audio.AudioLoopbackStatus.UNAVAILABLE_SCENE) {
      return 'Error';
    }
    return 'Monitoring off';
  }
}
