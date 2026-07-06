import { audio } from '@kit.AudioKit';
import { Logger } from '../common/Logger';
import { VolumeMath } from '../common/VolumeMath';
import { VolumeLevelInfo, VolumeStreamModel } from '../model/VolumeStreamModel';
import { VolumeGroupService } from './VolumeGroupService';

export type StreamVolumeChangeHandler = (event: audio.StreamVolumeEvent) => void;
export type VolumeChangeHandler = (event: audio.VolumeEvent) => void;

/**
 * Coordinates live system volume state for all dashboard streams.
 *
 * <p>The service prefers per-stream audio APIs, falls back to group APIs, and
 * manages stream volume listeners so the page can stay focused on rendering
 * and interaction state.</p>
 */
export class VolumeStateService {
  private volumeManager: audio.AudioVolumeManager;
  private groupService: VolumeGroupService;
  private isSubscribed: boolean = false;

  /**
   * Creates the service with platform volume access and group fallback support.
   *
   * @param volumeManager Platform volume manager used for stream APIs.
   * @param groupService Fallback service for default group lookups.
   */
  constructor(volumeManager: audio.AudioVolumeManager, groupService: VolumeGroupService) {
    this.volumeManager = volumeManager;
    this.groupService = groupService;
  }

  /**
   * Loads current platform volume values for every configured stream.
   *
   * @param streams Initial stream definitions to hydrate.
   * @returns Stream models populated with live volume, mute, and availability data.
   */
  async loadInitialVolumeState(streams: VolumeStreamModel[]): Promise<VolumeStreamModel[]> {
    Logger.init('load initial volume state started', `streams=${streams.length}`);
    const loaded: VolumeStreamModel[] = [];
    for (let index = 0; index < streams.length; index++) {
      const stream = streams[index];
      const info = await this.getStreamVolume(stream);
      stream.currentLevel = info.currentLevel;
      stream.minLevel = info.minLevel;
      stream.maxLevel = info.maxLevel;
      stream.percentage = info.percentage;
      stream.isAvailable = info.isAvailable;
      stream.isMuted = info.isMuted;
      stream.statusText = info.statusText;
      loaded.push(this.groupService.enrichStream(stream));
      Logger.volume('stream loaded',
        `stream=${stream.id}, available=${stream.isAvailable}, level=${stream.currentLevel}/${stream.maxLevel}, ` +
          `min=${stream.minLevel}, percent=${stream.percentage}, muted=${stream.isMuted}`);
    }
    Logger.init('load initial volume state finished', `loaded=${loaded.length}`);
    return loaded;
  }

  /**
   * Re-reads current platform volume values for existing stream cards.
   *
   * <p>This is used as a real-device fallback because some hardware/system
   * volume controls may not emit the per-stream callback to third-party apps.</p>
   *
   * @param streams Current stream models to refresh.
   * @returns Stream models updated with latest platform volume values.
   */
  async refreshVolumeState(streams: VolumeStreamModel[]): Promise<VolumeStreamModel[]> {
    const refreshed: VolumeStreamModel[] = [];
    for (let index = 0; index < streams.length; index++) {
      const stream = streams[index];
      const previousLevel = stream.currentLevel;
      const previousMuted = stream.isMuted;
      const info = await this.getStreamVolume(stream, false);
      stream.currentLevel = info.currentLevel;
      stream.minLevel = info.minLevel;
      stream.maxLevel = info.maxLevel;
      stream.percentage = info.percentage;
      stream.isAvailable = info.isAvailable;
      stream.isMuted = info.isMuted;
      stream.statusText = info.statusText;
      refreshed.push(this.groupService.enrichStream(stream));
      if (previousLevel !== stream.currentLevel || previousMuted !== stream.isMuted) {
        Logger.volume('refresh detected change',
          `stream=${stream.id}, from=${previousLevel}, to=${stream.currentLevel}, muted=${stream.isMuted}`);
      }
    }
    return refreshed;
  }

  /**
   * Reads current volume state for one stream.
   *
   * @param stream Stream definition to query.
   * @param shouldLog Whether lookup details should be written to hilog.
   * @returns Normalized volume information from stream APIs or fallback group APIs.
   */
  async getStreamVolume(stream: VolumeStreamModel, shouldLog: boolean = true): Promise<VolumeLevelInfo> {
    try {
      const minLevel = this.volumeManager.getMinVolumeByStream(stream.streamUsage);
      const maxLevel = this.volumeManager.getMaxVolumeByStream(stream.streamUsage);
      const currentLevel = this.volumeManager.getVolumeByStream(stream.streamUsage);
      const isMuted = this.volumeManager.isSystemMutedForStream(stream.streamUsage);
      if (shouldLog) {
        Logger.volume('stream api loaded',
          `stream=${stream.id}, level=${currentLevel}/${maxLevel}, min=${minLevel}, muted=${isMuted}`);
      }
      return {
        minLevel,
        maxLevel,
        currentLevel,
        percentage: VolumeMath.toPercentage(currentLevel, minLevel, maxLevel),
        isAvailable: true,
        isMuted,
        statusText: isMuted ? 'Muted' : 'Crown ready'
      };
    } catch (err) {
      if (shouldLog) {
        Logger.failure('VOLUME', `stream api unavailable stream=${stream.id}`, err);
      }
      const groupInfo = await this.groupService.getGroupVolumeInfo(stream, shouldLog);
      if (groupInfo !== undefined) {
        if (shouldLog) {
          Logger.volume('stream using group fallback', `stream=${stream.id}`);
        }
        return groupInfo;
      }
      if (shouldLog) {
        Logger.volume('stream unavailable', `stream=${stream.id}`);
      }
      return {
        minLevel: stream.minLevel,
        maxLevel: stream.maxLevel,
        currentLevel: stream.currentLevel,
        percentage: VolumeMath.toPercentage(stream.currentLevel, stream.minLevel, stream.maxLevel),
        isAvailable: false,
        isMuted: false,
        statusText: 'This volume type is not available on this device.'
      };
    }
  }

  /**
   * Subscribes to platform stream volume change events for all available streams.
   *
   * @param streams Streams whose usage values should be observed.
   * @param onStreamChange Callback invoked by the platform when a stream changes.
   * @param onVolumeChange Callback invoked by older/global system volume events.
   */
  subscribeVolumeChanges(streams: VolumeStreamModel[], onStreamChange: StreamVolumeChangeHandler,
    onVolumeChange: VolumeChangeHandler): void {
    this.unsubscribeVolumeChanges();
    let subscribedCount = 0;
    for (let index = 0; index < streams.length; index++) {
      const stream = streams[index];
      try {
        this.volumeManager.on('streamVolumeChange', stream.streamUsage, onStreamChange);
        this.isSubscribed = true;
        subscribedCount++;
        Logger.volume('listener subscribed', `stream=${stream.id}`);
      } catch (err) {
        Logger.failure('VOLUME', `listener unavailable stream=${stream.id}`, err);
      }
    }
    try {
      this.volumeManager.on('volumeChange', onVolumeChange);
      this.isSubscribed = true;
      Logger.volume('global listener subscribed');
    } catch (err) {
      Logger.failure('VOLUME', 'global listener unavailable', err);
    }
    Logger.volume('listener subscription finished', `count=${subscribedCount}/${streams.length}`);
  }

  /**
   * Removes any active stream volume subscriptions.
   */
  unsubscribeVolumeChanges(): void {
    if (!this.isSubscribed) {
      return;
    }

    try {
      this.volumeManager.off('streamVolumeChange');
      this.volumeManager.off('volumeChange');
      Logger.volume('listeners removed');
    } catch (err) {
      Logger.failure('VOLUME', 'unable to remove volume listeners', err);
    }
    this.isSubscribed = false;
  }
}
