/**
 * Compact circular percentage indicator used inside each ArcList card.
 *
 * <p>The component is intentionally small for round watch screens and only
 * renders visual state; callers remain responsible for volume calculations.</p>
 */
@Component
export struct VolumeRing {
  @Prop percentage: number;
  @Prop isSelected: boolean;
  @Prop isAvailable: boolean;

  /**
   * Renders the ring progress track and centered percentage label.
   */
  build() {
    Stack() {
      Progress({
        value: this.percentage,
        total: 100,
        type: ProgressType.Ring
      })
        .width(36)
        .height(36)
        .color(this.ringColor())
        .backgroundColor($r('app.color.ring_track'))
        .style({ strokeWidth: 5, scaleCount: 24, scaleWidth: 1 })

      Text(`${this.percentage}%`)
        .fontSize(9)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isAvailable ? $r('app.color.text_primary') : $r('app.color.text_disabled'))
    }
  }

  /**
   * Chooses the ring color based on availability and card selection.
   *
   * @returns Resource color for the active Progress stroke.
   */
  private ringColor(): ResourceColor {
    if (!this.isAvailable) {
      return $r('app.color.ring_muted');
    }
    return this.isSelected ? $r('app.color.accent_green') : $r('app.color.ring_idle');
  }
}
