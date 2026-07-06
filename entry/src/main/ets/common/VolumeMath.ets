/**
 * Volume normalization helpers. See design doc section 15.1.
 *
 * The UI must never assume a fixed maximum volume (such as 15). Percentages
 * are always derived from the live min / max / current values reported by the
 * audio manager.
 */
export class VolumeMath {
  /**
   * Converts a raw volume level into a rounded 0-100 percentage.
   *
   * @param current Current level reported by the platform.
   * @param min Minimum supported level for the stream or group.
   * @param max Maximum supported level for the stream or group.
   * @returns A display percentage, or {@code 0} when the range is invalid.
   */
  static toPercentage(current: number, min: number, max: number): number {
    if (max <= min) {
      return 0;
    }
    return Math.round(((current - min) / (max - min)) * 100);
  }

  /**
   * Clamps a numeric value into an inclusive range.
   *
   * @param value Candidate value.
   * @param min Inclusive lower bound.
   * @param max Inclusive upper bound.
   * @returns {@code value} limited to the supplied range.
   */
  static clamp(value: number, min: number, max: number): number {
    return Math.min(max, Math.max(min, value));
  }

  /**
   * Converts a 0-100 percentage back into a raw platform volume level.
   *
   * @param percentage Percentage selected by the UI.
   * @param min Minimum supported level for the stream or group.
   * @param max Maximum supported level for the stream or group.
   * @returns A rounded raw level within the supplied range.
   */
  static levelFromPercentage(percentage: number, min: number, max: number): number {
    if (max <= min) {
      return min;
    }
    const level: number = min + Math.round((percentage / 100) * (max - min));
    return VolumeMath.clamp(level, min, max);
  }
}
