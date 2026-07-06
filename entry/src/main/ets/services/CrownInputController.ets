import { VolumeMath } from '../common/VolumeMath';
import { VolumeStreamModel } from '../model/VolumeStreamModel';

/**
 * Pure input math for crown and compact button interactions.
 *
 * <p>This class avoids platform dependencies so navigation and step behavior
 * can be reasoned about separately from the page and audio services.</p>
 */
export class CrownInputController {
  /**
   * Calculates the next selected card index with wraparound.
   *
   * @param currentIndex Current ArcList/card index.
   * @param total Total number of selectable cards.
   * @param direction Positive for next, non-positive for previous.
   * @returns Wrapped next index, or {@code 0} when no cards exist.
   */
  nextIndex(currentIndex: number, total: number, direction: number): number {
    if (total <= 0) {
      return 0;
    }
    if (direction > 0) {
      return (currentIndex + 1) % total;
    }
    return (currentIndex - 1 + total) % total;
  }

  /**
   * Calculates the next raw volume level for a stream.
   *
   * @param stream Stream model containing current/min/max levels.
   * @param direction Positive for increase, non-positive for decrease.
   * @returns Clamped next raw level.
   */
  nextVolumeLevel(stream: VolumeStreamModel, direction: number): number {
    const step = direction > 0 ? 1 : -1;
    return VolumeMath.clamp(stream.currentLevel + step, stream.minLevel, stream.maxLevel);
  }

  /**
   * Calculates the next monitor volume percentage.
   *
   * @param currentVolume Current monitor volume from 0 to 100.
   * @param direction Positive for increase, non-positive for decrease.
   * @returns Monitor volume clamped to 0-100.
   */
  nextMonitorVolume(currentVolume: number, direction: number): number {
    const step = direction > 0 ? 5 : -5;
    return VolumeMath.clamp(currentVolume + step, 0, 100);
  }
}
