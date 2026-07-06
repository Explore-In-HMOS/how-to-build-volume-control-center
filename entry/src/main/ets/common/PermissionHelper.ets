import { abilityAccessCtrl, common, PermissionRequestResult, Permissions } from '@kit.AbilityKit';
import { Logger } from './Logger';

const MICROPHONE_PERMISSION: Permissions = 'ohos.permission.MICROPHONE';

/**
 * Handles runtime permission requests required by optional monitor features.
 *
 * <p>The dashboard keeps this logic outside the page so permission results can
 * be logged and tested independently from UI navigation.</p>
 */
export class PermissionHelper {
  /**
   * Requests microphone access from the current ability context.
   *
   * @param context Ability context used to display the platform permission UI.
   * @returns {@code true} when the user grants microphone access.
   */
  static async requestMicrophone(context: common.UIAbilityContext): Promise<boolean> {
    try {
      Logger.permission('microphone request shown');
      const manager = abilityAccessCtrl.createAtManager();
      const result: PermissionRequestResult =
        await manager.requestPermissionsFromUser(context, [MICROPHONE_PERMISSION]);
      const granted = result.authResults.length > 0 && result.authResults[0] === 0;
      Logger.permission('microphone request finished', `granted=${granted}, result=${Logger.describe(result)}`);
      return granted;
    } catch (err) {
      Logger.failure('PERMISSION', 'microphone request failed', err);
      return false;
    }
  }
}
