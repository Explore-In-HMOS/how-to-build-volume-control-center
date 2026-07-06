import { BackupExtensionAbility, BundleVersion } from '@kit.CoreFileKit';
import { Logger } from '../common/Logger';

/**
 * Backup extension for the application package.
 *
 * <p>The app currently has no persisted user data to back up or restore, but
 * the hooks are implemented and logged so backup lifecycle behavior can be
 * verified on real devices.</p>
 */
export default class EntryBackupAbility extends BackupExtensionAbility {
  /**
   * Handles platform backup requests.
   *
   * @returns A resolved promise because no app-specific backup payload exists.
   */
  async onBackup() {
    Logger.lifecycle('backup onBackup');
    await Promise.resolve();
  }

  /**
   * Handles platform restore requests.
   *
   * @param bundleVersion Version metadata for the bundle being restored.
   * @returns A resolved promise because no app-specific restore payload exists.
   */
  async onRestore(bundleVersion: BundleVersion) {
    Logger.lifecycle('backup onRestore', Logger.describe(bundleVersion));
    await Promise.resolve();
  }
}
