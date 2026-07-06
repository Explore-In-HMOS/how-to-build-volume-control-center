import { VolumeStreamModel } from '../model/VolumeStreamModel';
import { VolumeRing } from './VolumeRing';

/**
 * ArcList card that displays and selects one system volume stream.
 *
 * <p>The card is sized as a compact chip so notification/call/media entries
 * remain inside the safe area of a circular watch viewport.</p>
 */
@Component
export struct VolumeCard {
  @Prop stream: VolumeStreamModel;
  @Prop isSelected: boolean;
  @Prop isAdjusting: boolean;

  /**
   * Renders the stream icon, title, availability text, and percentage ring.
   */
  build() {
    Row() {
      Column() {
        Text(this.stream.iconText)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.stream.isAvailable ? $r('app.color.text_icon') : $r('app.color.icon_disabled'))
      }
      .width(26)
      .height(26)
      .justifyContent(FlexAlign.Center)
      .borderRadius(13)
      .backgroundColor(this.isSelected ? $r('app.color.stream_icon_bg_selected') : $r('app.color.stream_icon_bg'))

      Column() {
        Row() {
          Text(this.stream.label)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.stream.isAvailable ? $r('app.color.text_primary') : $r('app.color.text_disabled'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Blank()

          if (this.stream.isMuted) {
            Text($r('app.string.stream_muted'))
              .fontSize(9)
              .fontColor($r('app.color.warning_text'))
          }
        }
        .width('100%')

        Text(this.detailText())
          .fontSize(9)
          .fontColor(this.stream.isAvailable ? $r('app.color.text_secondary') : $r('app.color.text_disabled'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 1 })
      }
      .layoutWeight(1)
      .padding({ left: 7, right: 6 })

      VolumeRing({
        percentage: this.stream.percentage,
        isSelected: this.isSelected,
        isAvailable: this.stream.isAvailable
      })
    }
    .width(this.isSelected ? 188 : 168)
    .height(this.isSelected ? 58 : 50)
    .padding({ left: 7, right: 7 })
    .borderRadius(18)
    .border({
      width: this.isSelected ? 2 : 1,
      color: this.isSelected ? $r('app.color.accent_green') : $r('app.color.card_border')
    })
    .backgroundColor(this.cardColor())
    .opacity(this.stream.isAvailable ? 1 : 0.62)
    .clip(true)
  }

  /**
   * Builds the secondary status text shown under the stream label.
   *
   * @returns Current status, adjustment hint, or availability message.
   */
  private detailText(): string {
    if (!this.stream.isAvailable) {
      return this.stream.statusText;
    }
    const group = this.stream.groupName === undefined ? '' : ` ${this.stream.groupName}`;
    if (this.isSelected && this.isAdjusting) {
      return `Adjusting ${this.stream.currentLevel}/${this.stream.maxLevel}`;
    }
    return `${this.stream.statusText}${group}`;
  }

  /**
   * Chooses the card background for availability, selection, and adjustment state.
   *
   * @returns Resource color used as the card background.
   */
  private cardColor(): ResourceColor {
    if (!this.stream.isAvailable) {
      return $r('app.color.card_bg_unavailable');
    }
    if (this.isSelected && this.isAdjusting) {
      return $r('app.color.card_bg_adjusting');
    }
    if (this.isSelected) {
      return $r('app.color.card_bg_selected');
    }
    return $r('app.color.card_bg');
  }
}
