# hotpath.mbt：通常アプリと分離した開発用performance check

Status: open — 設計課題。既存profilerを再利用し、consumerの計測運用と回帰判定を定義する。
Priority: P1
Decision date: 2026-10-15
Parent: [ecosystem方針・共通マージ基準](https://github.com/gpui-mbt/gpui.mbt/pull/82)
Related: [dshの開発tool境界](https://github.com/f4ah6o/dsh.mbt/pull/65)

## 1. 役割

hotpathは「どの処理に時間がかかり、変更で悪化していないか」を測る開発用toolkitとして使う。gpui.mbt／Yami-kumo／MZed／dshの通常runtimeへ必須化しない。特にdshは独立した`tools/perf`から使い、アプリに常時計測を戻さない。

これはecosystemでの採用方針であり、汎用profiler APIを壊したり、他の利用者の明示的な組込み用途を禁止したりする変更ではない。

## 2. 現状

[README](../../README.md)には明示的scoped timing、集計、bounded histogram、text report、clock injection、`ProfilerNs`とnative monotonic clockがある。histogramのpercentileは近似値であり、raw sampleを内部保持しない。CPU／allocation samplingやCI回帰policy等は別課題として扱われている。

[dsh tools/perf](https://github.com/f4ah6o/dsh.mbt/blob/main/tools/perf/README.md)は既に独立したoptional moduleからHarnessApiを計測している。製品moduleからhotpathを外す作業を再実装せず、独立consumerと測定の信頼性を改善する。既存のperformance／report課題がある場合は本課題から関連付け、二重実装しない。

## 3. 責務・依存境界

1. hotpathはclock・scope・aggregate・reportを所有する。代表workload、製品の正しい出力、許容budgetはconsumerが所有する。
2. consumerは独立した開発module/workspaceまたはbenchmark fixtureから利用する。dshの通常module／配布物にhotpathを戻さず、削除済み`profile_stats`を復活させない。
3. turtlesはテスト検出力、gpui-conformanceは互換性、vlmkitはGUI観測を担当する。速さだけで正しさを保証せず、GUI描画完了を確認していない測定をframe latencyと呼ばない。
4. CPU使用率、allocation、GPU、実入力からframeまでのend-to-end時間は、実際に観測できるtoolと条件を用意したときだけ別metricとして追加する。現在のscoped timingから推定して埋めない。

## 4. 実装単位

1. **独立consumer recipe**：dsh tools/perfとgpuiの最小benchmarkを例に、明示したpublic APIを外側から測る。通常build／run／配布物がhotpathなしで成立する検査をconsumer側へ関連付ける。
2. **再現可能なworkload**：固定fixture、入力規模、出力checksum／state assertion、warmup、測定回数、実行modeを定義する。dshはkeyless・networkなし・ユーザーstoreなしの既存fixtureを再利用する。
3. **測定証拠**：baseline/candidate/toolのSHA、MoonBit/core、OS/arch/CPU、build flags、clockと実resolution、単位、sample数、warmup、overhead、raw sampleまたは近似集計の区別を保持する。raw sampleを必要とする分析ではcalling harness側で上限付き保存を行う。
4. **回帰policy**：まず同じrunner／toolchain／workloadのbaselineを確立し、consumerが事前に宣言した相対差と絶対差・ばらつきの条件で判定する。既存policy実装があれば拡張し、比較器を重複させない。未整備metricはreport-onlyと明示し、baselineなしをPASSと呼ばない。

## 5. 最初の測定範囲

| consumer | 初期metricの例 | 必須の補足 |
| --- | --- | --- |
| dsh tools/perf | 既存HarnessApiのsession作成、送信、stream投影、完了、session読出し | 実APIを呼び、同じ出力・状態であることをassertする |
| gpui.mbt | 固定treeのlayout／routing／scene生成 | tree規模と条件を固定し、renderer実表示とは分ける |
| Yami-kumo | component状態遷移／構築 | WebとNative、異なるruntimeの値を無条件に比較しない |
| MZed | bounded islandの処理scope | full editor速度やGPU frame時間へ一般化しない |

全consumerの計測導入を一度に必須化せず、最初は既存dsh recipeで1つのbaseline/candidate往復を完成させる。対象を増やすときはconsumer側の別課題と受入条件を用意する。

## 6. 受入条件・反例

| 対象 | 合格条件 |
| --- | --- |
| 製品境界 | 通常アプリはhotpathを導入せずbuild/runでき、optional計測だけが依存する |
| 測定対象 | fake clock／固定数値のreport例と実時間測定を明確に区別する |
| 同等workload | baselineとcandidateの入力・処理結果・build条件が一致する |
| clock | resolution・単位を記録し、逆行／不正sample／saturationを隠さない |
| overhead | 計測あり／なし等の対照を持ち、計測自体の費用を示す |
| 故意の遅延 | 固定fixtureの意図した悪化を比較器が検出する。閾値境界の検査は決定的dataで行う |
| 比較不能 | baseline欠損、条件違い、sample不足、clock異常を未検証／比較不能とする |
| 統計 | bucket近似p95/p99をexact percentileと呼ばず、外れ値やばらつきを説明する |
| 判定 | 依存削除だけで「高速化」、exit 0だけで「性能合格」と報告しない |

profileごとの結果を保存する。macOSはApple Silicon、Linux／Windowsは別条件。CIの機種差や雑音を隠して全OS共通の絶対速度を主張しない。失敗したbaselineを黙って更新して通さない。

## 7. 検証方法

既存の`moon check --target all`、`moon test --target all`、`moon bench --target native`、`moon fmt --check`を変更範囲に合わせて実行する。`examples/terminal_report`の固定sample出力は表示例であり実性能benchmarkではない。

consumerではdsh tools/perfの既存コマンドを使い、通常製品smokeと独立perfを別結果にする。今回のMarkdown追加では上記は未実行。実装時はコマンド・対象SHA・測定条件・PASS/FAIL/未実行と理由を記録する。

## 8. マージ基準・完了条件

共通`ecosystem-merge-v1`に従う。**最新HEADの必要CIがすべてcompleted/success AND 同じHEADに対する実際の`gpt-6.1-sol/xhigh`レビューのApprove相当**。モデル・effort・SHA・判定・指摘処置・証拠URLをGitHubへ記録する。P0/P1、必要checkのskip、未実行、古い承認を合格にせず、HEAD更新後は再検証・再レビューする。report-onlyを必要な性能gateの成功に偽装せず、既存保護を維持する。

1. [ ] 独立consumerから実workloadを計測し、通常アプリ非依存を維持する。
2. [ ] 同条件のbaseline/candidateと測定overhead・結果の正しさを記録する。
3. [ ] 故意の悪化と比較不能な条件を検出する。
4. [ ] consumer所有のbudgetと、未計測範囲・統計上の限界を明示する。
