import { audio } from '@kit.AudioKit';
import { common } from '@kit.AbilityKit';
import {
  ArcList,
  ArcListAttribute,
  ArcListItem,
  ArcListItemAttribute,
  LengthMetrics
} from '@kit.ArkUI';
import { VolumeCard } from '../components/VolumeCard';
import { MonitorModeCard } from '../components/MonitorModeCard';
import { SystemVolumePanelHost } from '../components/SystemVolumePanelHost';
import { CrownInputController } from '../services/CrownInputController';
import { AudioBootstrapService } from '../services/AudioBootstrapService';
import { VolumeGroupService } from '../services/VolumeGroupService';
import { VolumeStateService } from '../services/VolumeStateService';
import { LoopbackMonitorService } from '../services/LoopbackMonitorService';
import { VolumeDashboardState, createInitialVolumeDashboardState } from '../model/VolumeDashboardState';
import { VolumeStreamModel } from '../model/VolumeStreamModel';
import { VolumeMath } from '../common/VolumeMath';
import { Logger } from '../common/Logger';

/**
 * Main circular dashboard page for wearable volume control.
 *
 * <p>The page renders a Huawei {@code ArcList} of compact cards, handles crown
 * or button navigation, toggles adjustment mode, and delegates audio work to
 * services so lifecycle cleanup stays predictable on a real watch.</p>
 */
@Entry
@Component
struct Index {
  private bootstrapService: AudioBootstrapService = new AudioBootstrapService();
  private groupService: VolumeGroupService = new VolumeGroupService();
  private volumeStateService?: VolumeStateService;
  private loopbackService?: LoopbackMonitorService;
  private crownInputController: CrownInputController = new CrownInputController();
  private panelTimer: number = -1;
  private volumeSyncTimer: number = -1;
  private isPageActive: boolean = false;
  private initializationToken: number = 0;

  @State dashboardState: VolumeDashboardState = createInitialVolumeDashboardState();

  /**
   * Starts dashboard initialization when the page becomes visible.
   */
  aboutToAppear(): void {
    Logger.lifecycle('Index aboutToAppear');
    this.isPageActive = true;
    this.initializeDashboard();
  }

  /**
   * Releases listeners and monitor resources when the page leaves the tree.
   */
  aboutToDisappear(): void {
    Logger.lifecycle('Index aboutToDisappear');
    this.isPageActive = false;
    this.initializationToken++;
    if (this.volumeStateService !== undefined) {
      this.volumeStateService.unsubscribeVolumeChanges();
    }
    this.stopVolumeSyncTimer();
    this.clearPanelTimer();
    if (this.loopbackService !== undefined) {
      this.loopbackService.release();
    }
  }

  /**
   * Builds the full watch UI: header, ArcList cards, compact controls, and
   * optional platform volume panel.
   */
  build() {
    Stack() {
      Column() {
        Row() {
          Column() {
            Text($r('app.string.dashboard_title'))
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Text(this.modeText())
              .fontSize(11)
              .fontColor($r('app.color.text_muted'))
              .margin({ top: 2 })
          }
          .layoutWeight(1)

          Text(`${this.dashboardState.selectedIndex + 1}/${this.totalCards()}`)
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 6, right: 10 })
        }
        .width('100%')
        .padding({ left: 34, right: 34, top: 4, bottom: 2 })

        ArcList({ initialIndex: this.dashboardState.selectedIndex }) {
          ForEach(this.dashboardState.streams, (stream: VolumeStreamModel) => {
            ArcListItem() {
              VolumeCard({
                stream: stream,
                isSelected: this.dashboardState.selectedIndex === stream.displayOrder,
                isAdjusting: this.dashboardState.isAdjusting
              })
                .onClick(() => this.handleStreamTap(stream.displayOrder))
            }
            .autoScale(true)
          }, (stream: VolumeStreamModel) => stream.id)

          ArcListItem() {
            MonitorModeCard({
              monitorState: this.dashboardState.loopbackState,
              isSelected: this.isMonitorSelected(),
              isAdjusting: this.dashboardState.isAdjusting
            })
              .onClick(() => this.handleMonitorTap())
          }
          .autoScale(true)
        }
        .layoutWeight(1)
        .width('100%')
        .cachedCount(2)
        .chainAnimation(true)
        .digitalCrownSensitivity(CrownSensitivity.MEDIUM)
        .enableScrollInteraction(!this.dashboardState.isAdjusting)
        .fadingEdge(true)
        .scrollBar(BarState.Auto)
        .scrollBarWidth(LengthMetrics.vp(3))
        .onScrollIndex((start: number, end: number, center: number) => {
          this.handleArcCenterChange(center);
        })
        .parallelGesture(
          PanGesture({ direction: PanDirection.Vertical, distance: 14 })
            .onActionEnd((event: GestureEvent) => {
              this.handleTouchVolumeGesture(event.offsetY);
            })
        )

        Row({ space: 6 }) {
          Button() {
            Text($r('app.string.control_decrease'))
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
          }
            .width(28)
            .height(28)
            .padding(0)
            .borderRadius(14)
            .backgroundColor($r('app.color.control_button_bg'))
            .onClick(() => this.handleRotary(-1))

          Button() {
            Text(this.adjustmentButtonLabel())
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .maxLines(1)
          }
            .width(38)
            .height(28)
            .padding(0)
            .borderRadius(14)
            .backgroundColor(this.dashboardState.isAdjusting ?
              $r('app.color.control_primary_active_bg') : $r('app.color.control_primary_bg'))
            .onClick(() => this.toggleAdjustmentMode())

          Button() {
            Text($r('app.string.control_increase'))
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
          }
            .width(28)
            .height(28)
            .padding(0)
            .borderRadius(14)
            .backgroundColor($r('app.color.control_button_bg'))
            .onClick(() => this.handleRotary(1))
        }
        .width(108)
        .height(32)
        .justifyContent(FlexAlign.Center)
        .margin({ top: 2, bottom: 10 })
      }
      .width('100%')
      .height('100%')
      .padding({ left: 6, right: 6, top: 12, bottom: 4 })
      .backgroundColor($r('app.color.app_background'))

      SystemVolumePanelHost({
        isVisible: this.dashboardState.shouldShowPanel,
        volumeLevel: this.dashboardState.panelVolumeLevel
      })
    }
    .width('100%')
    .height('100%')
  }

  /**
   * Initializes audio services, loads stream state, probes monitor support, and
   * subscribes to system volume events.
   */
  private async initializeDashboard(): Promise<void> {
    const token = ++this.initializationToken;
    try {
      Logger.init('dashboard initialization started');
      this.bootstrapService.init();
      const audioManager = this.bootstrapService.getAudioManager();
      const volumeManager = this.bootstrapService.getVolumeManager();
      await this.groupService.initDefaultGroup(volumeManager, audioManager);
      this.volumeStateService = new VolumeStateService(volumeManager, this.groupService);
      this.loopbackService = new LoopbackMonitorService(audioManager);

      const streams = await this.volumeStateService.loadInitialVolumeState(this.dashboardState.streams);
      const loopbackState = await this.loopbackService.checkSupport(this.dashboardState.loopbackState);
      if (!this.isPageActive || token !== this.initializationToken) {
        Logger.init('dashboard initialization skipped', 'reason=page_inactive');
        return;
      }

      this.dashboardState = {
        streams,
        selectedIndex: 0,
        isAdjusting: false,
        panelVolumeLevel: streams[0].currentLevel,
        shouldShowPanel: false,
        loopbackState
      };
      Logger.init('dashboard initialization finished',
        `streams=${streams.length}, monitorSupported=${loopbackState.isSupported}`);

      this.volumeStateService.subscribeVolumeChanges(streams, (event: audio.StreamVolumeEvent) => {
        if (!this.isPageActive) {
          return;
        }
        this.applyStreamVolumeEvent(event);
      }, (event: audio.VolumeEvent) => {
        if (!this.isPageActive) {
          return;
        }
        this.applyVolumeEvent(event);
      });
      this.startVolumeSyncTimer();
    } catch (err) {
      Logger.failure('INIT', 'dashboard initialization failed', err);
      this.dashboardState.errorMessage = $r('app.string.dashboard_init_error');
    }
  }

  /**
   * Handles taps on a stream card.
   *
   * @param index Index of the tapped stream card.
   */
  private handleStreamTap(index: number): void {
    Logger.navigation('stream card tapped',
      `index=${index}, current=${this.dashboardState.selectedIndex}, adjusting=${this.dashboardState.isAdjusting}`);
    if (this.dashboardState.selectedIndex !== index) {
      this.dashboardState.selectedIndex = index;
      this.dashboardState.isAdjusting = false;
      this.dashboardState.shouldShowPanel = false;
      Logger.navigation('stream selected', `index=${index}, stream=${this.dashboardState.streams[index].id}`);
      return;
    }
    this.toggleAdjustmentMode();
  }

  /**
   * Syncs dashboard selection with the card centered by {@code ArcList}.
   *
   * @param center Centered ArcList item index reported by the framework.
   */
  private handleArcCenterChange(center: number): void {
    if (this.dashboardState.isAdjusting) {
      return;
    }
    if (center < 0 || center >= this.totalCards() || center === this.dashboardState.selectedIndex) {
      return;
    }
    Logger.navigation('arc center changed', `from=${this.dashboardState.selectedIndex}, to=${center}`);
    this.dashboardState.selectedIndex = center;
    this.dashboardState.shouldShowPanel = false;
    this.dashboardState.errorMessage = undefined;
  }

  /**
   * Handles monitor card selection and toggles monitor mode when already selected.
   */
  private async handleMonitorTap(): Promise<void> {
    const monitorIndex = this.dashboardState.streams.length;
    Logger.navigation('monitor card tapped',
      `current=${this.dashboardState.selectedIndex}, monitorIndex=${monitorIndex}, adjusting=${this.dashboardState.isAdjusting}`);
    if (this.dashboardState.selectedIndex !== monitorIndex) {
      this.dashboardState.selectedIndex = monitorIndex;
      this.dashboardState.isAdjusting = false;
      this.dashboardState.shouldShowPanel = false;
      Logger.navigation('monitor selected', `index=${monitorIndex}`);
      return;
    }

    if (this.loopbackService === undefined) {
      Logger.monitor('tap ignored', 'reason=service_missing');
      return;
    }

    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    let nextState = this.dashboardState.loopbackState;
    if (nextState.isEnabled) {
      nextState = await this.loopbackService.disableMonitor(nextState);
    } else {
      nextState = await this.loopbackService.enableMonitor(context, nextState);
      if (nextState.isEnabled) {
        this.observeMonitorStatus();
      }
    }
    this.dashboardState.loopbackState = nextState;
    this.dashboardState.isAdjusting = nextState.isEnabled;
    Logger.monitor('tap handled', `enabled=${nextState.isEnabled}, adjusting=${this.dashboardState.isAdjusting}`);
  }

  /**
   * Subscribes the page state to platform loopback status changes.
   *
   * <p>The callback is registered only after a loopback object exists. It keeps
   * the monitor card accurate if the system disables loopback because focus,
   * input device, or output device conditions changed.</p>
   */
  private observeMonitorStatus(): void {
    if (this.loopbackService === undefined) {
      return;
    }

    this.loopbackService.observeStatus((status: audio.AudioLoopbackStatus) => {
      if (!this.isPageActive || this.loopbackService === undefined) {
        return;
      }

      this.dashboardState.loopbackState.statusText = this.loopbackService.statusText(status);
      this.dashboardState.loopbackState.isEnabled = status === audio.AudioLoopbackStatus.AVAILABLE_RUNNING;
      if (this.isMonitorSelected()) {
        this.dashboardState.isAdjusting = this.dashboardState.loopbackState.isEnabled;
      }
      Logger.monitor('status changed', `status=${status}, enabled=${this.dashboardState.loopbackState.isEnabled}`);
    });
  }

  /**
   * Toggles adjustment mode for the selected stream or delegates monitor toggles.
   */
  private toggleAdjustmentMode(): void {
    if (this.isMonitorSelected()) {
      this.handleMonitorTap();
      return;
    }

    const selected = this.selectedStream();
    if (selected === undefined || !selected.isAvailable) {
      this.dashboardState.errorMessage = $r('app.string.unavailable_volume_message');
      Logger.volume('adjustment rejected', `index=${this.dashboardState.selectedIndex}`);
      return;
    }

    this.dashboardState.isAdjusting = !this.dashboardState.isAdjusting;
    this.dashboardState.shouldShowPanel = this.dashboardState.isAdjusting;
    this.dashboardState.panelVolumeLevel = selected.currentLevel;
    Logger.volume('adjustment toggled',
      `stream=${selected.id}, adjusting=${this.dashboardState.isAdjusting}, level=${selected.currentLevel}/${selected.maxLevel}`);
    if (this.dashboardState.isAdjusting) {
      this.schedulePanelHide();
    }
  }

  /**
   * Handles compact +/- button actions and crown-style directional changes.
   *
   * @param direction Positive to move/increase, negative to move/decrease.
   */
  private async handleRotary(direction: number): Promise<void> {
    if (!this.dashboardState.isAdjusting) {
      const previousIndex = this.dashboardState.selectedIndex;
      this.dashboardState.selectedIndex =
        this.crownInputController.nextIndex(this.dashboardState.selectedIndex, this.totalCards(), direction);
      this.dashboardState.shouldShowPanel = false;
      Logger.navigation('rotary moved selection',
        `direction=${direction}, from=${previousIndex}, to=${this.dashboardState.selectedIndex}`);
      return;
    }

    if (this.isMonitorSelected()) {
      if (this.loopbackService === undefined) {
        Logger.monitor('rotary ignored', 'reason=service_missing');
        return;
      }
      const current = this.dashboardState.loopbackState.monitorVolume;
      const nextVolume = this.crownInputController.nextMonitorVolume(current, direction);
      this.dashboardState.loopbackState =
        await this.loopbackService.setMonitorVolume(this.dashboardState.loopbackState, nextVolume);
      Logger.monitor('rotary volume changed', `direction=${direction}, from=${current}, to=${nextVolume}`);
      return;
    }

    const selected = this.selectedStream();
    if (selected === undefined || !selected.isAvailable) {
      Logger.volume('rotary ignored', `reason=stream_unavailable, index=${this.dashboardState.selectedIndex}`);
      return;
    }

    const previousLevel = selected.currentLevel;
    const nextLevel = this.crownInputController.nextVolumeLevel(selected, direction);
    const committed = await this.groupService.setGroupVolume(selected, nextLevel);
    if (!committed) {
      Logger.volume('rotary volume commit rejected',
        `stream=${selected.id}, direction=${direction}, from=${previousLevel}, requested=${nextLevel}`);
      this.refreshDashboardVolumeState('commit rejected');
      return;
    }

    selected.currentLevel = nextLevel;
    selected.percentage = VolumeMath.toPercentage(nextLevel, selected.minLevel, selected.maxLevel);
    this.dashboardState.panelVolumeLevel = nextLevel;
    this.dashboardState.shouldShowPanel = true;
    this.replaceSelectedStream(selected);
    Logger.volume('rotary volume changed',
      `stream=${selected.id}, direction=${direction}, from=${previousLevel}, to=${nextLevel}, percent=${selected.percentage}`);
    this.schedulePanelHide();
  }

  /**
   * Converts an adjustment-mode vertical drag into a one-step volume change.
   *
   * <p>The gesture is attached as a parallel recognizer so normal ArcList
   * scrolling still works in browse mode. It only changes volume after the user
   * has tapped SET and the current card is in adjustment mode.</p>
   *
   * @param offsetY Vertical drag distance in vp; negative means an upward drag.
   */
  private handleTouchVolumeGesture(offsetY: number): void {
    if (!this.dashboardState.isAdjusting) {
      return;
    }

    if (Math.abs(offsetY) < 14) {
      return;
    }

    const direction = offsetY < 0 ? 1 : -1;
    Logger.volume('touch volume gesture', `offsetY=${offsetY}, direction=${direction}`);
    this.handleRotary(direction);
  }

  /**
   * Applies platform volume-change events to the matching stream card.
   *
   * @param event Stream volume event emitted by the audio manager.
   */
  private applyStreamVolumeEvent(event: audio.StreamVolumeEvent): void {
    Logger.volume('system event received', Logger.describe(event));
    const updatedStreams = this.dashboardState.streams;
    for (let index = 0; index < updatedStreams.length; index++) {
      const stream = updatedStreams[index];
      if (stream.streamUsage === event.streamUsage) {
        stream.currentLevel = event.volume;
        stream.percentage = VolumeMath.toPercentage(event.volume, stream.minLevel, stream.maxLevel);
        stream.statusText = event.updateUi ? 'Changed by system' : 'Updated';
        updatedStreams[index] = stream;
        this.dashboardState.streams = updatedStreams;
        Logger.volume('system event applied',
          `stream=${stream.id}, level=${stream.currentLevel}/${stream.maxLevel}, percent=${stream.percentage}`);
        return;
      }
    }
    Logger.volume('system event ignored', 'reason=stream_not_found');
  }

  /**
   * Applies older/global system volume events to matching stream cards.
   *
   * @param event System volume event emitted by the audio manager.
   */
  private applyVolumeEvent(event: audio.VolumeEvent): void {
    Logger.volume('global system event received', Logger.describe(event));
    const updatedStreams = this.dashboardState.streams;
    let appliedCount = 0;
    for (let index = 0; index < updatedStreams.length; index++) {
      const stream = updatedStreams[index];
      if (stream.fallbackVolumeType === event.volumeType) {
        stream.currentLevel = event.volume;
        stream.percentage = VolumeMath.toPercentage(event.volume, stream.minLevel, stream.maxLevel);
        stream.statusText = event.updateUi ? 'Changed by system' : 'Updated';
        updatedStreams[index] = stream;
        if (this.dashboardState.selectedIndex === index) {
          this.dashboardState.panelVolumeLevel = event.volume;
        }
        appliedCount++;
        Logger.volume('global system event applied',
          `stream=${stream.id}, level=${stream.currentLevel}/${stream.maxLevel}, percent=${stream.percentage}`);
      }
    }
    if (appliedCount > 0) {
      this.dashboardState.streams = updatedStreams;
      this.refreshDashboardVolumeState('global event verify');
      return;
    }
    Logger.volume('global system event ignored', `volumeType=${event.volumeType}`);
    this.refreshDashboardVolumeState('global event fallback');
  }

  /**
   * Schedules automatic hiding of the system volume panel.
   */
  private schedulePanelHide(): void {
    this.clearPanelTimer();
    this.panelTimer = setTimeout(() => {
      if (!this.isPageActive) {
        this.panelTimer = -1;
        return;
      }
      this.dashboardState.shouldShowPanel = false;
      this.panelTimer = -1;
      Logger.volume('panel hidden');
    }, 1800);
  }

  /**
   * Cancels any pending hide timer for the transient platform volume panel.
   */
  private clearPanelTimer(): void {
    if (this.panelTimer < 0) {
      return;
    }
    clearTimeout(this.panelTimer);
    this.panelTimer = -1;
  }

  /**
   * Starts periodic platform re-read for devices that suppress volume callbacks.
   */
  private startVolumeSyncTimer(): void {
    this.stopVolumeSyncTimer();
    this.volumeSyncTimer = setInterval(() => {
      this.refreshDashboardVolumeState('timer');
    }, 1500);
    Logger.volume('sync timer started');
  }

  /**
   * Stops the periodic platform volume sync timer.
   */
  private stopVolumeSyncTimer(): void {
    if (this.volumeSyncTimer < 0) {
      return;
    }
    clearInterval(this.volumeSyncTimer);
    this.volumeSyncTimer = -1;
    Logger.volume('sync timer stopped');
  }

  /**
   * Re-reads platform volume state and updates cards when values changed.
   *
   * @param reason Short reason for diagnostic logs.
   */
  private async refreshDashboardVolumeState(reason: string): Promise<void> {
    if (!this.isPageActive || this.volumeStateService === undefined) {
      return;
    }
    const previousStreams = this.dashboardState.streams;
    const previousLevels = previousStreams.map((stream: VolumeStreamModel) => stream.currentLevel);
    const previousMuteStates = previousStreams.map((stream: VolumeStreamModel) => stream.isMuted);
    const refreshedStreams = await this.volumeStateService.refreshVolumeState(previousStreams);
    if (!this.isPageActive) {
      return;
    }

    let changed = false;
    for (let index = 0; index < refreshedStreams.length; index++) {
      if (refreshedStreams[index].currentLevel !== previousLevels[index] ||
        refreshedStreams[index].isMuted !== previousMuteStates[index]) {
        changed = true;
        break;
      }
    }
    this.dashboardState.streams = refreshedStreams;
    const selected = this.selectedStream();
    if (selected !== undefined) {
      this.dashboardState.panelVolumeLevel = selected.currentLevel;
    }
    if (changed) {
      Logger.volume('dashboard refreshed', `reason=${reason}`);
    }
  }

  /**
   * Replaces the selected stream in state after a local volume change.
   *
   * @param stream Updated stream model.
   */
  private replaceSelectedStream(stream: VolumeStreamModel): void {
    const streams = this.dashboardState.streams;
    streams[this.dashboardState.selectedIndex] = stream;
    this.dashboardState.streams = streams;
  }

  /**
   * Reads the currently selected stream if the selection points to a stream card.
   *
   * @returns Selected stream or {@code undefined} when the monitor card is selected.
   */
  private selectedStream(): VolumeStreamModel | undefined {
    if (this.dashboardState.selectedIndex >= this.dashboardState.streams.length) {
      return undefined;
    }
    return this.dashboardState.streams[this.dashboardState.selectedIndex];
  }

  /**
   * Checks whether the monitor card is the current selection.
   *
   * @returns {@code true} when the selected index is the monitor card.
   */
  private isMonitorSelected(): boolean {
    return this.dashboardState.selectedIndex === this.dashboardState.streams.length;
  }

  /**
   * Calculates the number of selectable cards in the ArcList.
   *
   * @returns Stream count plus the monitor card.
   */
  private totalCards(): number {
    return this.dashboardState.streams.length + 1;
  }

  /**
   * Chooses the header subtitle for current mode or error state.
   *
   * @returns Resource string shown beneath the title.
   */
  private modeText(): ResourceStr {
    if (this.dashboardState.errorMessage !== undefined) {
      return this.dashboardState.errorMessage;
    }
    return this.dashboardState.isAdjusting ? $r('app.string.adjustment_mode') : $r('app.string.navigation_mode');
  }

  /**
   * Chooses the center control label for adjustment mode.
   *
   * @returns {@code SET} when browsing, {@code OK} when adjusting.
   */
  private adjustmentButtonLabel(): ResourceStr {
    return this.dashboardState.isAdjusting ? $r('app.string.control_ok') : $r('app.string.control_set');
  }
}
