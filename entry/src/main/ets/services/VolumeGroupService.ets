import { audio } from '@kit.AudioKit';
import { Logger } from '../common/Logger';
import { VolumeMath } from '../common/VolumeMath';
import { VolumeLevelInfo, VolumeStreamModel } from '../model/VolumeStreamModel';

/**
 * Fallback service for legacy/default audio volume group APIs.
 *
 * <p>Modern stream APIs are preferred, but some real watch firmware may expose
 * certain controls only through the default volume group. This service isolates
 * that compatibility path and records when it is used.</p>
 */
export class VolumeGroupService {
  private groupManager?: audio.AudioVolumeGroupManager;
  private audioManager?: audio.AudioManager;
  private groupAvailable: boolean = false;

  /**
   * Attempts to initialize the default volume group manager.
   *
   * @param volumeManager Platform volume manager from {@link AudioBootstrapService}.
   * @param audioManager Legacy audio manager used as a compatibility setter.
   */
  async initDefaultGroup(volumeManager: audio.AudioVolumeManager, audioManager?: audio.AudioManager): Promise<void> {
    this.audioManager = audioManager;
    try {
      this.groupManager = await volumeManager.getVolumeGroupManager(audio.DEFAULT_VOLUME_GROUP_ID);
      this.groupAvailable = true;
      Logger.init('default volume group ready', `groupId=${audio.DEFAULT_VOLUME_GROUP_ID}`);
    } catch (err) {
      this.groupAvailable = false;
      Logger.failure('INIT', 'default volume group unavailable', err);
    }
  }

  /**
   * Adds group metadata to a loaded stream when a group manager is available.
   *
   * @param stream Stream model to enrich.
   * @returns The same stream model with optional group name populated.
   */
  enrichStream(stream: VolumeStreamModel): VolumeStreamModel {
    stream.groupName = this.groupAvailable ? 'Default' : undefined;
    return stream;
  }

  /**
   * Reads volume information through the fallback group manager.
   *
   * @param stream Stream whose fallback volume type should be queried.
   * @param shouldLog Whether successful/failure lookup details should be logged.
   * @returns Normalized volume information, or {@code undefined} when unavailable.
   */
  async getGroupVolumeInfo(stream: VolumeStreamModel, shouldLog: boolean = true): Promise<VolumeLevelInfo | undefined> {
    if (this.groupManager === undefined) {
      return undefined;
    }

    try {
      const minLevel = await this.groupManager.getMinVolume(stream.fallbackVolumeType);
      const maxLevel = await this.groupManager.getMaxVolume(stream.fallbackVolumeType);
      const currentLevel = await this.groupManager.getVolume(stream.fallbackVolumeType);
      const isMuted = await this.groupManager.isMute(stream.fallbackVolumeType);
      if (shouldLog) {
        Logger.volume('group fallback loaded',
          `stream=${stream.id}, level=${currentLevel}/${maxLevel}, min=${minLevel}, muted=${isMuted}`);
      }
      return {
        minLevel,
        maxLevel,
        currentLevel,
        percentage: VolumeMath.toPercentage(currentLevel, minLevel, maxLevel),
        isAvailable: true,
        isMuted,
        statusText: isMuted ? 'Muted' : 'Output Group: Default'
      };
    } catch (err) {
      if (shouldLog) {
        Logger.failure('VOLUME', `group stream lookup failed stream=${stream.id}`, err);
      }
      return undefined;
    }
  }

  /**
   * Commits a stream level to the system volume service.
   *
   * <p>The current SDK exposes stream reads through {@code AudioVolumeManager},
   * but this project still needs a watch-compatible setter. The available typed
   * setter in this SDK is the compatibility {@code AudioManager#setVolume} API.</p>
   *
   * @param stream Stream whose fallback volume type should be set.
   * @param level Raw volume level to commit.
   * @returns {@code true} when a platform setter succeeds.
   */
  async setGroupVolume(stream: VolumeStreamModel, level: number): Promise<boolean> {
    if (this.audioManager !== undefined) {
      try {
        await this.audioManager.setVolume(stream.fallbackVolumeType, level);
        Logger.volume('system volume committed',
          `api=audioManager, stream=${stream.id}, volumeType=${stream.fallbackVolumeType}, level=${level}`);
        return true;
      } catch (err) {
        Logger.failure('VOLUME', `audio manager volume commit failed stream=${stream.id}`, err);
      }
    }

    Logger.volume('system volume commit unavailable',
      `stream=${stream.id}, volumeType=${stream.fallbackVolumeType}, level=${level}`);
    return false;
  }
}
