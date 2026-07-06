import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { Logger } from '../common/Logger';

/**
 * Main UI ability for the wearable volume dashboard.
 *
 * <p>The ability owns application/window lifecycle logging and loads the ArkUI
 * page that contains the circular watch interface.</p>
 */
export default class EntryAbility extends UIAbility {
  /**
   * Handles ability creation and applies the app color-mode policy.
   *
   * @param want Launch want provided by the system.
   * @param launchParam System launch metadata.
   */
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    Logger.lifecycle('onCreate', `want=${Logger.describe(want)}, launch=${Logger.describe(launchParam)}`);
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      Logger.failure('LIFECYCLE', 'setColorMode failed', err);
    }
  }

  /**
   * Logs ability destruction.
   */
  onDestroy(): void {
    Logger.lifecycle('onDestroy');
  }

  /**
   * Loads the dashboard page when the ability window stage is ready.
   *
   * @param windowStage Window stage supplied by the framework.
   */
  onWindowStageCreate(windowStage: window.WindowStage): void {
    Logger.lifecycle('onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        Logger.failure('LIFECYCLE', 'loadContent failed', err);
        return;
      }
      Logger.lifecycle('loadContent succeeded', 'page=pages/Index');
    });
  }

  /**
   * Logs window-stage teardown before UI resources are released by the system.
   */
  onWindowStageDestroy(): void {
    Logger.lifecycle('onWindowStageDestroy');
  }

  /**
   * Logs foreground transitions for real-watch lifecycle testing.
   */
  onForeground(): void {
    Logger.lifecycle('onForeground');
  }

  /**
   * Logs background transitions for real-watch lifecycle testing.
   */
  onBackground(): void {
    Logger.lifecycle('onBackground');
  }
}
