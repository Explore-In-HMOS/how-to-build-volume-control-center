import { LoopbackMonitorState } from '../model/LoopbackMonitorState';
import { VolumeRing } from './VolumeRing';

/**
 * ArcList card for the optional hardware loopback monitor mode.
 *
 * <p>The card mirrors {@link VolumeCard} sizing so it scrolls consistently
 * with stream cards on circular wearable displays.</p>
 */
@Component
export struct MonitorModeCard {
  @Prop monitorState: LoopbackMonitorState;
  @Prop isSelected: boolean;
  @Prop isAdjusting: boolean;

  /**
   * Renders monitor support, enabled state, and monitor volume.
   */
  build() {
    Row() {
      Column() {
        Text($r('app.string.monitor_icon'))
          .fontSize(9)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.monitorState.isSupported ? $r('app.color.text_icon') : $r('app.color.icon_disabled'))
      }
      .width(30)
      .height(26)
      .justifyContent(FlexAlign.Center)
      .borderRadius(13)
      .backgroundColor(this.isSelected ? $r('app.color.monitor_icon_bg_selected') : $r('app.color.monitor_icon_bg'))

      Column() {
        Row() {
          Text($r('app.string.monitor_label'))
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.monitorState.isSupported ? $r('app.color.text_primary') : $r('app.color.text_disabled'))
          Blank()
          Text(this.monitorState.isEnabled ? $r('app.string.monitor_on') : $r('app.string.monitor_off'))
            .fontSize(9)
            .fontColor(this.monitorState.isEnabled ? $r('app.color.accent_green') : $r('app.color.text_secondary'))
        }
        .width('100%')

        Text(this.monitorState.statusText)
          .fontSize(9)
          .fontColor(this.monitorState.isSupported ? $r('app.color.text_secondary') : $r('app.color.text_disabled'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 1 })
      }
      .layoutWeight(1)
      .padding({ left: 7, right: 6 })

      VolumeRing({
        percentage: this.monitorState.monitorVolume,
        isSelected: this.isSelected,
        isAvailable: this.monitorState.isSupported
      })
    }
    .width(this.isSelected ? 188 : 168)
    .height(this.isSelected ? 58 : 50)
    .padding({ left: 7, right: 7 })
    .borderRadius(18)
    .border({
      width: this.isSelected ? 2 : 1,
      color: this.isSelected ? $r('app.color.accent_monitor') : $r('app.color.card_border')
    })
    .backgroundColor(this.cardColor())
    .opacity(this.monitorState.isSupported ? 1 : 0.62)
    .clip(true)
  }

  /**
   * Chooses the monitor card background for support, selection, and active mode.
   *
   * @returns Resource color used as the card background.
   */
  private cardColor(): ResourceColor {
    if (!this.monitorState.isSupported) {
      return $r('app.color.card_bg_unavailable');
    }
    if (this.isSelected && this.isAdjusting) {
      return $r('app.color.monitor_bg_adjusting');
    }
    if (this.isSelected) {
      return $r('app.color.monitor_bg_selected');
    }
    return $r('app.color.card_bg');
  }
}
