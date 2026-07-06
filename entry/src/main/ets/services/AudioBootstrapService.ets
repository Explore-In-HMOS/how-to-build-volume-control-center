import { audio } from '@kit.AudioKit';
import { Logger } from '../common/Logger';

/**
 * Lazy bootstrapper for HarmonyOS audio managers.
 *
 * <p>The app accesses audio APIs from several services. This class keeps
 * manager creation centralized and logs whether a call initializes or reuses
 * the cached platform managers.</p>
 */
export class AudioBootstrapService {
  private audioManager?: audio.AudioManager;
  private volumeManager?: audio.AudioVolumeManager;

  /**
   * Initializes audio and volume managers if they are not already cached.
   */
  init(): void {
    if (this.audioManager !== undefined && this.volumeManager !== undefined) {
      Logger.init('audio services reused');
      return;
    }

    this.audioManager = audio.getAudioManager();
    this.volumeManager = this.audioManager.getVolumeManager();
    Logger.init('audio services initialized');
  }

  /**
   * Gets the shared audio manager, initializing it if necessary.
   *
   * @returns Platform audio manager.
   */
  getAudioManager(): audio.AudioManager {
    this.init();
    return this.audioManager as audio.AudioManager;
  }

  /**
   * Gets the shared volume manager, initializing it if necessary.
   *
   * @returns Platform volume manager.
   */
  getVolumeManager(): audio.AudioVolumeManager {
    this.init();
    return this.volumeManager as audio.AudioVolumeManager;
  }
}
