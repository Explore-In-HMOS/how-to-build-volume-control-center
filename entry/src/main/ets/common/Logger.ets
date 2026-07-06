import { hilog } from '@kit.PerformanceAnalysisKit';

export const LOG_DOMAIN: number = 0x0001;
export const LOG_TAG: string = 'WearableVolume';

/**
 * Central logging facade for the watch app.
 *
 * <p>All production diagnostics go through this class so real-device testing
 * can filter a single hilog domain and tag: {@link LOG_DOMAIN} /
 * {@link LOG_TAG}. Category helpers intentionally produce stable prefixes
 * such as {@code LIFECYCLE}, {@code INIT}, and {@code VOLUME} so test notes can
 * reference exact log families.</p>
 */
export class Logger {
  /**
   * Writes an informational hilog entry.
   *
   * @param message Public diagnostic message to emit.
   */
  static info(message: string): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, '%{public}s', message);
  }

  /**
   * Writes a warning hilog entry.
   *
   * @param message Public diagnostic message that indicates degraded behavior.
   */
  static warn(message: string): void {
    hilog.warn(LOG_DOMAIN, LOG_TAG, '%{public}s', message);
  }

  /**
   * Writes an error hilog entry.
   *
   * @param message Public diagnostic message that indicates failed behavior.
   */
  static error(message: string): void {
    hilog.error(LOG_DOMAIN, LOG_TAG, '%{public}s', message);
  }

  /**
   * Writes a debug hilog entry.
   *
   * @param message Public diagnostic message for verbose investigation.
   */
  static debug(message: string): void {
    hilog.debug(LOG_DOMAIN, LOG_TAG, '%{public}s', message);
  }

  /**
   * Logs ability/page lifecycle transitions.
   *
   * @param event Lifecycle event name.
   * @param details Optional structured context for the event.
   */
  static lifecycle(event: string, details?: string): void {
    Logger.info(Logger.format('LIFECYCLE', event, details));
  }

  /**
   * Logs startup and service initialization work.
   *
   * @param event Initialization step name.
   * @param details Optional structured context for the step.
   */
  static init(event: string, details?: string): void {
    Logger.info(Logger.format('INIT', event, details));
  }

  /**
   * Logs user navigation across ArcList cards and selection changes.
   *
   * @param event Navigation event name.
   * @param details Optional structured context for the event.
   */
  static navigation(event: string, details?: string): void {
    Logger.info(Logger.format('NAV', event, details));
  }

  /**
   * Logs volume stream reads, updates, subscriptions, and system callbacks.
   *
   * @param event Volume event name.
   * @param details Optional structured context for the event.
   */
  static volume(event: string, details?: string): void {
    Logger.info(Logger.format('VOLUME', event, details));
  }

  /**
   * Logs monitor/loopback support, permission, and runtime actions.
   *
   * @param event Monitor event name.
   * @param details Optional structured context for the event.
   */
  static monitor(event: string, details?: string): void {
    Logger.info(Logger.format('MONITOR', event, details));
  }

  /**
   * Logs runtime permission request flow.
   *
   * @param event Permission event name.
   * @param details Optional structured context for the event.
   */
  static permission(event: string, details?: string): void {
    Logger.info(Logger.format('PERMISSION', event, details));
  }

  /**
   * Logs a failed operation with a category and serialized error payload.
   *
   * @param area Stable log category, for example {@code INIT} or {@code VOLUME}.
   * @param event Human-readable failed operation.
   * @param err Error object or message returned by the platform call.
   */
  static failure(area: string, event: string, err: Object | string): void {
    Logger.error(Logger.format(area, event, Logger.describe(err)));
  }

  /**
   * Converts arbitrary values into log-safe public text.
   *
   * @param value Value to serialize for hilog.
   * @returns A best-effort string representation.
   */
  static describe(value: Object | string | number | boolean | undefined): string {
    if (value === undefined) {
      return 'undefined';
    }
    if (typeof value === 'string') {
      return value;
    }
    try {
      return JSON.stringify(value);
    } catch (err) {
      return `${value}`;
    }
  }

  /**
   * Builds the category-prefixed log message used by all helper methods.
   *
   * @param area Stable category prefix.
   * @param event Event name inside the category.
   * @param details Optional structured details appended after a separator.
   * @returns Formatted public log message.
   */
  private static format(area: string, event: string, details?: string): string {
    if (details === undefined || details.length === 0) {
      return `${area} ${event}`;
    }
    return `${area} ${event} | ${details}`;
  }
}
