import { AVVolumePanel, AVVolumePanelParameter } from '@kit.AudioKit';

/**
 * Hosts the platform volume panel while the app is in adjustment mode.
 *
 * <p>The dashboard owns visibility and volume level state; this component only
 * adapts that state into the platform {@link AVVolumePanel} API.</p>
 */
@Component
export struct SystemVolumePanelHost {
  @Prop isVisible: boolean;
  @Prop volumeLevel: number;

  /**
   * Renders the system panel when requested by the dashboard.
   */
  build() {
    if (this.isVisible) {
      AVVolumePanel({
        volumeLevel: this.volumeLevel,
        volumeParameter: this.panelParameter()
      })
    }
  }

  /**
   * Creates the platform panel positioning object.
   *
   * @returns Volume panel parameters tuned for the circular watch layout.
   */
  private panelParameter(): AVVolumePanelParameter {
    const parameter = new AVVolumePanelParameter();
    parameter.position = { x: 22, y: 176 };
    return parameter;
  }
}
