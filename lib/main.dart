import 'package:flutter/material.dart';
import 'dart:async'; // タイマー（Timer）を使うために必要です
import 'login_screen.dart';

// アプリのエントリーポイント（ここからプログラムが始まります）
void main() {
  runApp(const AttendanceApp());
}

// アプリ全体の基本設定を行うクラス
class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '勤怠管理',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginScreen(
        appName: '勤怠管理',
        originalHome: AttendanceHomePage(),
      ),
    );
  }
}

// Data Models
// メンバーの状態を表す列挙型（作業中、休憩中、時間超過、欠席）
enum MemberStatus { working, onBreak, overtime, absent }

// メンバー（社員）の情報を管理するクラス
class Member {
  final String name;
  final String job;
  final int totalBreakTime;
  final int elapsedBreakTime;
  final MemberStatus status;
  final IconData icon;

  // --- タイマー機能用の追加フィールド ---
  final int workMinutes; // 設定された作業時間（分）
  final int breakMinutes; // 設定された休憩時間（分）
  final int remainingSeconds; // 現在のフェーズの残り時間（秒）
  final bool isWorkPhase; // 現在が作業中かどうか（true: 作業中, false: 休憩中）
  final bool isTimerActive; // タイマーが動いているかどうか
  final bool isOverdue; // 時間が経過してアラート待機中かどうか

  // --- 打刻時間用の追加フィールド ---
  final String? attendanceTime;
  final String? leaveTime;
  final String? earlyLeaveTime;
  final String? pauseTime;
  final String? lastStampDate; // 打刻された日付（YYYY-MM-DD形式）
  final Map<String, Map<String, String?>>
  workHistory; // 過去の打刻履歴 {日付: {項目名: 時刻}}

  Member({
    required this.name,
    required this.job,
    required this.totalBreakTime,
    required this.elapsedBreakTime,
    required this.status,
    required this.icon,
    this.workMinutes = 0,
    this.breakMinutes = 0,
    this.remainingSeconds = 0,
    this.isWorkPhase = true,
    this.isTimerActive = false,
    this.isOverdue = false,
    this.attendanceTime,
    this.leaveTime,
    this.earlyLeaveTime,
    this.pauseTime,
    this.lastStampDate,
    this.workHistory = const {},
  });

  // 休憩時間の進捗率を計算する（0.0〜1.0）
  // タイマーが動いている場合は、タイマーの残り時間に基づいた進捗を返します
  double get progress {
    if (isTimerActive) {
      int totalSeconds = (isWorkPhase ? workMinutes : breakMinutes) * 60;
      if (totalSeconds == 0) return 0;
      return (totalSeconds - remainingSeconds) / totalSeconds;
    }
    return totalBreakTime == 0 ? 0 : elapsedBreakTime / totalBreakTime;
  }

  // 既存のメンバー情報を元に、一部のデータだけを変更した新しいインスタンスを作成します
  Member copyWith({
    String? name,
    String? job,
    int? totalBreakTime,
    int? elapsedBreakTime,
    MemberStatus? status,
    IconData? icon,
    int? workMinutes,
    int? breakMinutes,
    int? remainingSeconds,
    bool? isWorkPhase,
    bool? isTimerActive,
    bool? isOverdue,
    String? attendanceTime,
    String? leaveTime,
    String? earlyLeaveTime,
    String? pauseTime,
    String? lastStampDate,
    Map<String, Map<String, String?>>? workHistory,
  }) {
    return Member(
      name: name ?? this.name,
      job: job ?? this.job,
      totalBreakTime: totalBreakTime ?? this.totalBreakTime,
      elapsedBreakTime: elapsedBreakTime ?? this.elapsedBreakTime,
      status: status ?? this.status,
      icon: icon ?? this.icon,
      workMinutes: workMinutes ?? this.workMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isWorkPhase: isWorkPhase ?? this.isWorkPhase,
      isTimerActive: isTimerActive ?? this.isTimerActive,
      isOverdue: isOverdue ?? this.isOverdue,
      attendanceTime: attendanceTime ?? this.attendanceTime,
      leaveTime: leaveTime ?? this.leaveTime,
      earlyLeaveTime: earlyLeaveTime ?? this.earlyLeaveTime,
      pauseTime: pauseTime ?? this.pauseTime,
      lastStampDate: lastStampDate ?? this.lastStampDate,
      workHistory: workHistory ?? this.workHistory,
    );
  }

  // 打刻情報を全てクリアした新しいインスタンスを返します（5時リセット用）
  Member clearStamps() {
    return Member(
      name: name,
      job: job,
      totalBreakTime: totalBreakTime,
      elapsedBreakTime: elapsedBreakTime,
      status: status,
      icon: icon,
      workMinutes: 0,
      breakMinutes: 0,
      remainingSeconds: 0,
      isWorkPhase: true,
      isTimerActive: false,
      isOverdue: false,
      attendanceTime: null,
      leaveTime: null,
      earlyLeaveTime: null,
      pauseTime: null,
      lastStampDate: null, // 表示用の日付のみ一旦クリアする（履歴保存後に呼び出す想定）
      workHistory: workHistory,
    );
  }
}

// 休憩場所（ソファーなど）の情報を管理するクラス
class BreakSpot {
  final String name;
  final bool isOccupied;
  final int? remainingMinutes;
  final String? userName;

  BreakSpot({
    required this.name,
    required this.isOccupied,
    this.remainingMinutes,
    this.userName,
  });
}

// 週間シフト表示画面
class WeeklyShiftScreen extends StatelessWidget {
  final Member member;

  const WeeklyShiftScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${member.name}の週間シフト')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFFFDFBF)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '曜日 / 日付',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '勤務予定',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const Divider(thickness: 2),
              Expanded(
                child: ListView.separated(
                  itemCount: 7,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final days = ['月', '火', '水', '木', '金', '土', '日'];
                    final now = DateTime.now();
                    final date = now.add(Duration(days: index));
                    final dateStr = '${date.month}/${date.day}';
                    final dayOfWeek = days[date.weekday - 1];

                    // ShiftConfirmScreenのダミーデータから状態を取得
                    // 2025年11月のデータなので、デモとして日付（day）をキーにする
                    final state =
                        ShiftConfirmScreen.confirmedShifts[date.day] ?? 0;

                    String statusLabel = '休み';
                    Color btnColor = Colors.grey[300]!;
                    switch (state) {
                      case 1:
                        statusLabel = '10:00~15:00';
                        btnColor = Colors.blue;
                        break;
                      case 2:
                        statusLabel = '10:00~15:00';
                        btnColor = Colors.lightBlue;
                        break;
                      case 3:
                        statusLabel = '10:00~15:00';
                        btnColor = const Color(0xFF98D8C8);
                        break;
                      case 4:
                        statusLabel = '休み'; // 有給も休みと表示
                        btnColor = Colors.green;
                        break;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                dayOfWeek,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: btnColor,
                                  borderRadius: BorderRadius.circular(4), // 長方形
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  dateStr,
                                  style: TextStyle(
                                    color:
                                        state > 0
                                            ? Colors.white
                                            : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color:
                                  state > 0 && state != 4
                                      ? btnColor
                                      : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // 凡例の追加
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildLegendItem(Colors.blue, '出勤'),
                        _buildLegendItem(Colors.lightBlue, 'リモート'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildLegendItem(const Color(0xFF98D8C8), '可能性あり'),
                        _buildLegendItem(Colors.green, '有給'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

// ホーム画面（メンバー一覧と休憩場所一覧を表示）
class AttendanceHomePage extends StatefulWidget {
  const AttendanceHomePage({super.key});

  @override
  State<AttendanceHomePage> createState() => _AttendanceHomePageState();
}

class _AttendanceHomePageState extends State<AttendanceHomePage> {
  // メンバーのデータリストを状態として保持します
  late List<Member> members;
  late List<BreakSpot> breakSpots;
  Timer? _globalTimer; // 全体の時間を管理するタイマー

  @override
  void initState() {
    super.initState();
    // 初期データの作成
    members = [
      Member(
        name: '田中 太郎',
        job: 'イラスト',
        totalBreakTime: 0,
        elapsedBreakTime: 0,
        status: MemberStatus.working,
        icon: Icons.face,
      ),
      Member(
        name: '佐藤 花子',
        job: 'DTM',
        totalBreakTime: 0,
        elapsedBreakTime: 0,
        status: MemberStatus.working,
        icon: Icons.face_3,
      ),
      Member(
        name: '鈴木 一郎',
        job: '３Dモデリング',
        totalBreakTime: 0,
        elapsedBreakTime: 0,
        status: MemberStatus.onBreak,
        icon: Icons.face_6,
      ),
      Member(
        name: '髙橋 美咲',
        job: 'イラスト',
        totalBreakTime: 0,
        elapsedBreakTime: 0,
        status: MemberStatus.overtime,
        icon: Icons.face_2,
      ),
      Member(
        name: '佐々木 健一',
        job: '',
        totalBreakTime: 0,
        elapsedBreakTime: 0,
        status: MemberStatus.absent,
        icon: Icons.person_off,
      ),
      Member(
        name: '山田 圭太',
        job: '',
        totalBreakTime: 0,
        elapsedBreakTime: 0,
        status: MemberStatus.absent,
        icon: Icons.person_off,
      ),
    ];

    breakSpots = [
      BreakSpot(
        name: 'ソファー1',
        isOccupied: true,
        remainingMinutes: 2,
        userName: '鈴木 一郎',
      ),
      BreakSpot(name: 'ソファー2', isOccupied: false),
    ];

    // 1秒ごとに実行されるタイマーを開始します
    _globalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _tick();
    });
  }

  @override
  void dispose() {
    _globalTimer?.cancel(); // 画面が閉じられたらタイマーを止めます
    super.dispose();
  }

  // 1秒ごとに呼ばれ、全メンバーのタイマーを進める関数
  void _tick() {
    setState(() {
      for (int i = 0; i < members.length; i++) {
        final m = members[i];
        if (m.isTimerActive) {
          // タイマーが継続して減るようにします（超過時もカウントを続けます）
          members[i] = m.copyWith(remainingSeconds: m.remainingSeconds - 1);

          // 0になった瞬間に超過フラグを立てます（すでに立っている場合はそのまま）
          if (members[i].remainingSeconds <= 0 && !m.isOverdue) {
            members[i] = members[i].copyWith(isOverdue: true);
          }
        }
      }
    });
  }

  // 指定したメンバーの情報を更新する関数
  void _updateMember(String name, Member updatedMember) {
    setState(() {
      final index = members.indexWhere((m) => m.name == name);
      if (index != -1) {
        members[index] = updatedMember;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('勤怠管理'), centerTitle: true),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFFFDFBF)],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Member Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'メンバー',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        // Handle settings tap
                      },
                      child: const Row(
                        children: [
                          Text('設定'),
                          SizedBox(width: 4),
                          Icon(Icons.settings),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Members Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.6,
                  ),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    return MemberTile(
                      member: members[index],
                      // メンバーが更新された時に呼ばれるコールバックを渡します
                      onChanged:
                          (updatedMember) =>
                              _updateMember(members[index].name, updatedMember),
                      // 最新のメンバー情報を取得するための関数を渡します
                      getLatestMember: () => members[index],
                    );
                  },
                ),
                const SizedBox(height: 20),
                // Divider
                const Divider(color: Colors.grey, thickness: 1),
                const SizedBox(height: 20),
                // Break Spots Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: breakSpots.length,
                  itemBuilder: (context, index) {
                    return BreakSpotTile(spot: breakSpots[index]);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MemberTile extends StatelessWidget {
  final Member member;
  final Function(Member) onChanged;
  final Member Function() getLatestMember;

  const MemberTile({
    super.key,
    required this.member,
    required this.onChanged,
    required this.getLatestMember,
  });

  @override
  Widget build(BuildContext context) {
    Color progressColor;
    String statusText;
    double progressValue = member.progress;
    int remainingTime = member.totalBreakTime - member.elapsedBreakTime;
    String remainingTimeText = '残り$remainingTime分';
    Color remainingTimeColor = Colors.black;

    // シフト確認から本日の状態を取得して欠席かどうかを判定
    final int today = DateTime.now().day;
    final int shiftState = ShiftConfirmScreen.confirmedShifts[today] ?? 0;
    // 1: 出勤予定, 2: リモート, 3: 出勤可能性あり 以外（0や4など）かつ、出勤打刻がない場合は「本日欠席」とみなす
    final bool isAbsentToday =
        (shiftState != 1 && shiftState != 2 && shiftState != 3) &&
        member.attendanceTime == null;

    IconData displayIcon = member.icon;

    // メンバーの状態（タイマーの状態）に応じて色やテキストを決定
    if (isAbsentToday) {
      progressColor = Colors.black;
      statusText = '本日欠席';
      progressValue = 1.0;
      displayIcon = Icons.person_off;
      remainingTimeText = '';
    } else if (member.leaveTime != null) {
      // 退勤ボタンが押された後
      progressColor = Colors.blue;
      statusText = '業務終了';
      progressValue = 1.0;
      remainingTimeText = '';
    } else if (member.attendanceTime == null) {
      // 出勤予定の日で、出勤ボタンを押す前
      progressColor = Colors.blue;
      statusText = '10:00に出勤';
      progressValue = 0.0;
      remainingTimeText = '';
    } else if (member.isOverdue) {
      progressColor = Colors.red;
      statusText = '時間超過';
      progressValue = 1.0;
      remainingTimeColor = Colors.red;

      // 超過時間を計算（負の値になっているので絶対値をとる）
      int overdueTotalSeconds = member.remainingSeconds.abs();
      int overdueMinutes = overdueTotalSeconds ~/ 60;
      int overdueSeconds = overdueTotalSeconds % 60;
      remainingTimeText = '$overdueMinutes分$overdueSeconds秒超過';
    } else if (member.isTimerActive) {
      if (member.isWorkPhase) {
        progressColor = Colors.blue;
        statusText = '作業中';
      } else {
        progressColor = Colors.grey;
        statusText = '休憩中';
      }
      int minutes = member.remainingSeconds ~/ 60;
      int seconds = member.remainingSeconds % 60;
      remainingTimeText = '残り $minutes:${seconds.toString().padLeft(2, '0')}';
    } else {
      // タイマーが動いていない場合のデフォルト表示
      switch (member.status) {
        case MemberStatus.working:
          progressColor = Colors.blue;
          statusText = '作業中';
          break;
        case MemberStatus.onBreak:
          progressColor = Colors.grey;
          statusText = '休憩中';
          break;
        case MemberStatus.overtime:
          progressColor = Colors.red;
          statusText = '時間超過';
          progressValue = 1.0;
          break;
        case MemberStatus.absent:
          progressColor = Colors.black;
          statusText = '本日欠席';
          progressValue = 1.0;
          displayIcon = Icons.person_off;
          break;
      }
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Shift Button (Top Right)
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WeeklyShiftScreen(member: member),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'シフト',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            // Main Content (Centered)
            Expanded(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => MemberDetailScreen(
                            member: member,
                            onChanged: onChanged,
                            getLatestMember: getLatestMember,
                          ),
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Circular Progress Bar
                    SizedBox(
                      width: 90, // Increased by 16px (74 + 16)
                      height: 90, // Increased by 16px
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 8,
                            color:
                                (member.isTimerActive && !member.isOverdue)
                                    ? (member.isWorkPhase
                                        ? Colors.blue
                                        : Colors.grey[700])
                                    : Colors.grey[200],
                          ),
                          CircularProgressIndicator(
                            value: progressValue,
                            strokeWidth: 8,
                            color:
                                (member.isTimerActive && !member.isOverdue)
                                    ? (member.isWorkPhase
                                        ? Colors.grey[300]
                                        : Colors.grey[400])
                                    : progressColor,
                          ),
                          Center(
                            child: Icon(
                              displayIcon,
                              size: 45, // Increased proportionally
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Name
                    Text(
                      member.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    // Job Description (if present)
                    if (member.job.isNotEmpty)
                      Text(
                        member.job,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    // Status Text
                    Text(
                      statusText,
                      style: TextStyle(
                        color: progressColor,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (member.status != MemberStatus.absent &&
                        member.isTimerActive) ...[
                      Text(
                        '${((member.isWorkPhase ? member.workMinutes : member.breakMinutes) * 60 - member.remainingSeconds) ~/ 60}分 / ${(member.isWorkPhase ? member.workMinutes : member.breakMinutes)}分',
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: remainingTimeColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            remainingTimeText,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: remainingTimeColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 休憩場所のタイル表示
class BreakSpotTile extends StatelessWidget {
  final BreakSpot spot;

  const BreakSpotTile({super.key, required this.spot});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200], // Light grey background
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            spot.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (spot.isOccupied) ...[
            const Text(
              '使用中',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            if (spot.userName != null)
              Text(
                spot.userName!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (spot.remainingMinutes != null)
              Text(
                'あと${spot.remainingMinutes}分後に空き',
                style: const TextStyle(fontSize: 12),
              ),
          ] else
            const Text(
              '使用可能',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}

// メンバーの詳細画面（出勤・退勤ボタンや休憩設定など）
class MemberDetailScreen extends StatefulWidget {
  final Member member;
  final Function(Member) onChanged;
  final Member Function() getLatestMember;

  const MemberDetailScreen({
    super.key,
    required this.member,
    required this.onChanged,
    required this.getLatestMember,
  });

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  // 休止ダイアログで選択されている「休止時間」と「休憩場所」の初期値
  String _selectedPauseTime = '14:30';
  String _selectedRestSpot = 'ソファー1';

  // 「本日の作業」入力用のコントローラー
  late TextEditingController _jobController;
  // 作業時間と休憩時間の入力用コントローラー
  late TextEditingController _workMinutesController;
  late TextEditingController _breakMinutesController;

  Timer? _localUpdateTimer; // 画面を更新し続けるためのローカルタイマー
  bool _isDialogShowing = false; // アラートが二重に出ないように制御

  @override
  void initState() {
    super.initState();
    _jobController = TextEditingController(text: widget.member.job);
    _workMinutesController = TextEditingController(
      text: widget.member.workMinutes.toString(),
    );
    _breakMinutesController = TextEditingController(
      text: widget.member.breakMinutes.toString(),
    );

    // 詳細画面でも1秒ごとに setState して、ホーム画面のタイマー更新を反映させます
    _localUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _checkAndResetStamps(); // 5時リセットのチェック
        setState(() {}); // ステータスやプログレスバーを更新
        _checkOverdue();
      }
    });
  }

  // 05:00を基準とした「業務日」の日付文字列を取得する
  String _getBusinessDate(DateTime dt) {
    // 00:00 〜 04:59 までは前日扱いとする
    if (dt.hour < 5) {
      final prevDay = dt.subtract(const Duration(days: 1));
      return "${prevDay.year}-${prevDay.month.toString().padLeft(2, '0')}-${prevDay.day.toString().padLeft(2, '0')}";
    }
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  // 日付が変わっている（5時を跨いでいる）場合、打刻をリセットする
  void _checkAndResetStamps() {
    final currentMember = widget.getLatestMember();
    final todayBusinessDate = _getBusinessDate(DateTime.now());

    // 最後に打刻された日付が現在の業務日と異なる場合、リセット
    if (currentMember.lastStampDate != null &&
        currentMember.lastStampDate != todayBusinessDate) {
      final updatedMember = currentMember.clearStamps();
      widget.onChanged(updatedMember);
    }
  }

  @override
  void dispose() {
    _jobController.dispose();
    _workMinutesController.dispose();
    _breakMinutesController.dispose();
    _localUpdateTimer?.cancel();
    super.dispose();
  }

  // 時間超過になったかチェックし、アラートを表示する関数
  void _checkOverdue() {
    final currentMember = widget.getLatestMember();
    if (currentMember.isOverdue && !_isDialogShowing) {
      _isDialogShowing = true;
      String message = currentMember.isWorkPhase ? '休憩時間です' : '作業時間です';

      showDialog(
        context: context,
        barrierDismissible: false, // OKを押すまで閉じられないようにします
        builder:
            (context) => AlertDialog(
              title: const Text('お知らせ'),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () {
                    _isDialogShowing = false;
                    Navigator.pop(context); // ダイアログを閉じる
                    _switchToNextPhase();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  // 「OK」を押した後に、次のフェーズ（作業→休憩 または 休憩→作業）に切り替える関数
  void _switchToNextPhase() {
    final currentMember = widget.getLatestMember();
    bool nextIsWork = !currentMember.isWorkPhase;
    int nextMinutes =
        nextIsWork ? currentMember.workMinutes : currentMember.breakMinutes;

    final updatedMember = currentMember.copyWith(
      isWorkPhase: nextIsWork,
      remainingSeconds: nextMinutes * 60,
      isOverdue: false,
    );
    widget.onChanged(updatedMember);
    setState(() {}); // 即座に画面を更新
  }

  // タイマーを開始・リセットする関数
  void _startTimer() {
    int w = int.tryParse(_workMinutesController.text) ?? 5; // デフォルト5分
    int b = int.tryParse(_breakMinutesController.text) ?? 2; // デフォルト2分

    final updatedMember = widget.getLatestMember().copyWith(
      workMinutes: w,
      breakMinutes: b,
      remainingSeconds: w * 60,
      isWorkPhase: true,
      isTimerActive: true,
      isOverdue: false,
    );
    widget.onChanged(updatedMember);
    setState(() {}); // 決定した瞬間にタイマーが表示されるように即座に更新
  }

  // 現在の時刻を「HH:mm」形式（例：14:05）で取得する便利な関数
  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  // 出勤ボタンが押された時の処理
  void _handleAttendance() {
    final currentTime = _getCurrentTime(); // 現在時刻を取得
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            content: Text('（$currentTime）に出勤しました'),
            actions: [
              TextButton(
                onPressed: () {
                  // 会員情報を更新し、ホーム画面にも反映させます
                  final currentMember = widget.getLatestMember();
                  final businessDate = _getBusinessDate(DateTime.now());
                  final newHistory = Map<String, Map<String, String?>>.from(
                    currentMember.workHistory,
                  );
                  final dayHistory = Map<String, String?>.from(
                    newHistory[businessDate] ?? {},
                  );
                  dayHistory['attendanceTime'] = currentTime;
                  newHistory[businessDate] = dayHistory;

                  final updatedMember = currentMember.copyWith(
                    attendanceTime: currentTime,
                    lastStampDate: businessDate,
                    workHistory: newHistory,
                  );
                  widget.onChanged(updatedMember);
                  setState(() {});
                  Navigator.pop(context); // ダイアログを閉じる
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _handleLeave() {
    final currentTime = _getCurrentTime();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            content: Text('（$currentTime）に退勤しました'),
            actions: [
              TextButton(
                onPressed: () {
                  final currentMember = widget.getLatestMember();
                  final businessDate = _getBusinessDate(DateTime.now());
                  final newHistory = Map<String, Map<String, String?>>.from(
                    currentMember.workHistory,
                  );
                  final dayHistory = Map<String, String?>.from(
                    newHistory[businessDate] ?? {},
                  );
                  dayHistory['leaveTime'] = currentTime;
                  newHistory[businessDate] = dayHistory;

                  final updatedMember = currentMember.copyWith(
                    leaveTime: currentTime,
                    lastStampDate: businessDate,
                    workHistory: newHistory,
                  );
                  widget.onChanged(updatedMember);
                  setState(() {});
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _handleEarlyLeave() {
    final currentTime = _getCurrentTime();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            content: Text('（$currentTime）に早退しました'),
            actions: [
              TextButton(
                onPressed: () {
                  final currentMember = widget.getLatestMember();
                  final businessDate = _getBusinessDate(DateTime.now());
                  final newHistory = Map<String, Map<String, String?>>.from(
                    currentMember.workHistory,
                  );
                  final dayHistory = Map<String, String?>.from(
                    newHistory[businessDate] ?? {},
                  );
                  dayHistory['earlyLeaveTime'] = currentTime;
                  newHistory[businessDate] = dayHistory;

                  final updatedMember = currentMember.copyWith(
                    earlyLeaveTime: currentTime,
                    lastStampDate: businessDate,
                    workHistory: newHistory,
                  );
                  widget.onChanged(updatedMember);
                  setState(() {});
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  // 休止ボタンが押された時の処理
  void _handlePause() {
    showDialog(
      context: context,
      builder: (context) {
        // ダイアログ内の状態（ドロップダウンやラジオボタンの選択）を即座に反映させるためのウィジェット
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min, // コンテンツに合わせて最小の高さにする
                children: [
                  // 時間選択のドロップダウン
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DropdownButton<String>(
                        value: _selectedPauseTime,
                        items:
                            ['14:00', '14:30', '15:00', '15:30'].map((
                              String value,
                            ) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            // ダイアログの中（setDialogState）と、親の画面（setState）の両方を更新
                            setDialogState(() {
                              _selectedPauseTime = newValue;
                            });
                            setState(() {
                              _selectedPauseTime = newValue;
                            });
                          }
                        },
                      ),
                      const Text('まで休止します。'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 休憩場所を選択するラジオボタン（ソファー1）
                  RadioListTile<String>(
                    title: const Text('ソファー1'),
                    value: 'ソファー1',
                    groupValue: _selectedRestSpot,
                    onChanged: (String? value) {
                      if (value != null) {
                        setDialogState(() => _selectedRestSpot = value);
                        setState(() => _selectedRestSpot = value);
                      }
                    },
                  ),
                  // 休憩場所を選択するラジオボタン（ソファー2）
                  RadioListTile<String>(
                    title: const Text('ソファー2'),
                    value: 'ソファー2',
                    groupValue: _selectedRestSpot,
                    onChanged: (String? value) {
                      if (value != null) {
                        setDialogState(() => _selectedRestSpot = value);
                        setState(() => _selectedRestSpot = value);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // OKボタンで最終的な休止時刻を決定
                    final currentMember = widget.getLatestMember();
                    final businessDate = _getBusinessDate(DateTime.now());
                    final newHistory = Map<String, Map<String, String?>>.from(
                      currentMember.workHistory,
                    );
                    final dayHistory = Map<String, String?>.from(
                      newHistory[businessDate] ?? {},
                    );
                    dayHistory['pauseTime'] = _selectedPauseTime;
                    newHistory[businessDate] = dayHistory;

                    final updatedMember = currentMember.copyWith(
                      pauseTime: _selectedPauseTime,
                      lastStampDate: businessDate,
                      workHistory: newHistory,
                    );
                    widget.onChanged(updatedMember);
                    setState(() {});
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 親画面（AttendanceHomePage）にある最新のメンバー情報を取得して表示に使用します
    final currentMember = widget.getLatestMember();

    Color progressColor;
    String statusText;
    double progressValue = currentMember.progress;
    String timerDisplayText;
    Color timerDisplayColor = Colors.black;

    // 勤務情報の計算 (10:00 - 15:00)
    final now = DateTime.now();
    final startTime = DateTime(now.year, now.month, now.day, 10, 0);
    final endTime = DateTime(now.year, now.month, now.day, 15, 0);

    double workingHoursProgress = 0.0;
    String remainingTo1500Text = '残り時間（5時間00分）';

    if (now.isAfter(endTime)) {
      workingHoursProgress = 1.0;
      remainingTo1500Text = '残り時間（0分）';
    } else if (now.isAfter(startTime)) {
      final totalMinutes = endTime.difference(startTime).inMinutes;
      final elapsedMinutes = now.difference(startTime).inMinutes;
      workingHoursProgress = elapsedMinutes / totalMinutes;

      final remainingMinutesTotal = endTime.difference(now).inMinutes;
      final h = remainingMinutesTotal ~/ 60;
      final m = remainingMinutesTotal % 60;
      if (h > 0) {
        remainingTo1500Text = '残り時間（${h}時間${m.toString().padLeft(2, '0')}分）';
      } else {
        remainingTo1500Text = '残り時間（${m}分）';
      }
    }

    // シフト確認から本日の状態を取得して欠席かどうかを判定
    final int today = DateTime.now().day;
    final int shiftState = ShiftConfirmScreen.confirmedShifts[today] ?? 0;
    final bool isAbsentToday =
        (shiftState != 1 && shiftState != 2 && shiftState != 3) &&
        currentMember.attendanceTime == null;

    IconData displayIcon = widget.member.icon;

    // メンバーの状態（タイマーの状態）に応じて表示色などを決定
    if (isAbsentToday) {
      progressColor = Colors.black;
      statusText = '本日欠席';
      progressValue = 1.0;
      displayIcon = Icons.person_off;
      timerDisplayText = '';
    } else if (currentMember.leaveTime != null) {
      // 退勤ボタンが押された後
      progressColor = Colors.blue;
      statusText = '業務終了';
      progressValue = 1.0;
      timerDisplayText = '';
    } else if (currentMember.attendanceTime == null) {
      // 出勤前
      progressColor = Colors.blue;
      statusText = '10:00に出勤';
      progressValue = 0.0;
      timerDisplayText = '';
    } else if (currentMember.isOverdue) {
      progressColor = Colors.red;
      statusText = '時間超過';
      progressValue = 1.0;
      timerDisplayColor = Colors.red;

      // 超過時間を計算（負の値になっているので絶対値をとる）
      int overdueTotalSeconds = currentMember.remainingSeconds.abs();
      int overdueMinutes = overdueTotalSeconds ~/ 60;
      int overdueSeconds = overdueTotalSeconds % 60;
      timerDisplayText = '$overdueMinutes分$overdueSeconds秒超過';
    } else if (currentMember.isTimerActive) {
      if (currentMember.isWorkPhase) {
        progressColor = Colors.blue;
        statusText = '作業中';
      } else {
        progressColor = Colors.grey;
        statusText = '休憩中';
      }
      progressValue = currentMember.progress;
      int minutes = currentMember.remainingSeconds ~/ 60;
      int seconds = currentMember.remainingSeconds % 60;
      timerDisplayText = '残り $minutes:${seconds.toString().padLeft(2, '0')}';
    } else {
      timerDisplayText = '';
      switch (currentMember.status) {
        case MemberStatus.working:
          progressColor = Colors.blue;
          statusText = '作業中';
          break;
        case MemberStatus.onBreak:
          progressColor = Colors.grey;
          statusText = '休憩中';
          break;
        case MemberStatus.overtime:
          progressColor = Colors.red;
          statusText = '時間超過';
          progressValue = 1.0;
          break;
        case MemberStatus.absent:
          progressColor = Colors.black;
          statusText = '本日欠席';
          progressValue = 1.0;
          break;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.member.name)),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFFFDFBF)],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // 出勤・退勤・早退・休止ボタン
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTimeButton(
                        '出勤',
                        widget.member.attendanceTime,
                        _handleAttendance,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTimeButton(
                        '退勤',
                        widget.member.leaveTime,
                        _handleLeave,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTimeButton(
                        '早退',
                        widget.member.earlyLeaveTime,
                        _handleEarlyLeave,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTimeButton(
                        '休止',
                        widget.member.pauseTime,
                        _handlePause,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 「本日の作業」入力欄
                Row(
                  children: [
                    const Text(
                      '本日の作業',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _jobController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 保存ボタン
                    ElevatedButton(
                      onPressed: () {
                        // 入力内容を親画面に伝えます
                        widget.onChanged(
                          currentMember.copyWith(job: _jobController.text),
                        );
                        // 保存完了のメッセージを表示
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('保存しました')));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text('保存'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Status
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
                const SizedBox(height: 20),
                // Circular Progress Bar
                SizedBox(
                  width: 150,
                  height: 150,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Center(
                        child: SizedBox(
                          width: 150,
                          height: 150,
                          child: CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 12,
                            color:
                                (currentMember.isTimerActive &&
                                        !currentMember.isOverdue)
                                    ? (currentMember.isWorkPhase
                                        ? Colors.blue
                                        : Colors.grey[700])
                                    : Colors.grey[300],
                          ),
                        ),
                      ),
                      Center(
                        child: SizedBox(
                          width: 150,
                          height: 150,
                          child: CircularProgressIndicator(
                            value: progressValue,
                            strokeWidth: 12,
                            color:
                                (currentMember.isTimerActive &&
                                        !currentMember.isOverdue)
                                    ? (currentMember.isWorkPhase
                                        ? Colors.grey[300]
                                        : Colors.grey[400])
                                    : progressColor,
                          ),
                        ),
                      ),
                      Center(
                        child: Icon(
                          displayIcon,
                          size: 70,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                if (currentMember.isTimerActive || currentMember.isOverdue)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 20,
                        color: timerDisplayColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timerDisplayText,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: timerDisplayColor,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 30),
                // 休憩設定（何分に一回、何分休憩するか）
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 60,
                          child: TextField(
                            controller: _workMinutesController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.all(8),
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('分に一回'),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 60,
                          child: TextField(
                            controller: _breakMinutesController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.all(8),
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('分休憩'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // タイマー開始ボタン（改行して表示）
                    ElevatedButton(
                      onPressed: _startTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        '決定',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // 勤務時間の進捗バー
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '勤務時間',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: workingHoursProgress,
                  minHeight: 20,
                  backgroundColor: Colors.grey[300],
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(height: 4),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text('10:00'), Text('15:00')],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [Text(remainingTo1500Text)],
                ),
                const SizedBox(height: 40),
                // 画面下部の遷移ボタン（労働実績、シフト確認、シフト希望表）
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSquareButton(context, '労働実績'),
                    _buildSquareButton(context, 'シフト確認'),
                    _buildSquareButton(context, 'シフト希望表'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 時刻を表示するボタン（上のボタン部分）を作成する補助関数
  Widget _buildTimeButton(String text, String? time, VoidCallback onTap) {
    // メンバーオブジェクトから最新の時間を取得するようにします
    final currentMember = widget.getLatestMember();
    String? displayTime;
    if (text == '出勤') displayTime = currentMember.attendanceTime;
    if (text == '退勤') displayTime = currentMember.leaveTime;
    if (text == '早退') displayTime = currentMember.earlyLeaveTime;
    if (text == '休止') displayTime = currentMember.pauseTime;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSquareButton(context, text, width: double.infinity, onTap: onTap),
        const SizedBox(height: 4),
        // 時刻が記録されている場合は太字で表示
        Text(
          displayTime ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
        ),
      ],
    );
  }

  // 四角いボタンを作成する共通の関数
  Widget _buildSquareButton(
    BuildContext context,
    String text, {
    double? width,
    VoidCallback? onTap,
  }) {
    return Container(
      width: width ?? 100,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        // タップされた時の動作。onTapが渡されていなければ、デフォルトの画面遷移を行う
        onTap:
            onTap ??
            () {
              // 最新のメンバー情報を取得してから画面遷移する（workHistory等が反映されるように）
              final latestMember = widget.getLatestMember();
              if (text == '労働実績') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => WorkRecordScreen(member: latestMember),
                  ),
                );
              } else if (text == 'シフト希望表') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ShiftRequestScreen(member: latestMember),
                  ),
                );
              } else if (text == 'シフト確認') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ShiftConfirmScreen(member: latestMember),
                  ),
                );
              }
            },
        child: Center(
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

// 労働実績画面（週間・月間のグラフと給与内訳を表示）
class WorkRecordScreen extends StatefulWidget {
  final Member member;

  const WorkRecordScreen({super.key, required this.member});

  @override
  State<WorkRecordScreen> createState() => _WorkRecordScreenState();
}

// 労働実績画面の状態管理クラス
class _WorkRecordScreenState extends State<WorkRecordScreen> {
  String viewMode = '週間表示'; // 表示モード（週間/月間）
  late String selectedMonth; // 選択中の月（例：3月）
  late int selectedYear; // 選択中の年

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedMonth = '${now.month}月';
    selectedYear = now.year;
  }

  // 利用可能な月のリストを取得（今月から過去3ヶ月分）
  List<String> get availableMonths {
    final now = DateTime.now();
    return List.generate(3, (i) {
      final date = DateTime(now.year, now.month - i, 1);
      return '${date.month}月';
    });
  }

  // 週間データ（月〜日）
  List<Map<String, dynamic>> get weeklyData {
    final List<Map<String, dynamic>> data = [
      {'day': '月', 'basic': 0.0, 'overtime': 0.0, 'night': 0.0, 'leave': 0.0},
      {'day': '火', 'basic': 0.0, 'overtime': 0.0, 'night': 0.0, 'leave': 0.0},
      {'day': '水', 'basic': 0.0, 'overtime': 0.0, 'night': 0.0, 'leave': 0.0},
      {'day': '木', 'basic': 0.0, 'overtime': 0.0, 'night': 0.0, 'leave': 0.0},
      {'day': '金', 'basic': 0.0, 'overtime': 0.0, 'night': 0.0, 'leave': 0.0},
      {'day': '土', 'basic': 0.0, 'overtime': 0.0, 'night': 0.0, 'leave': 0.0},
      {'day': '日', 'basic': 0.0, 'overtime': 0.0, 'night': 0.0, 'leave': 0.0},
    ];

    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      // 月曜日を起点とした日付を計算
      final date = now.subtract(Duration(days: now.weekday - 1 - i));
      final dateStr =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      // 有給休暇のチェック
      if (ShiftConfirmScreen.confirmedShifts[date.day] == 4) {
        data[i]['leave'] = 4.0;
      }

      // 履歴データからの取得
      final dayHistory = widget.member.workHistory[dateStr];
      if (dayHistory != null) {
        final stats = _calculateStats(
          dayHistory['attendanceTime'],
          dayHistory['leaveTime'],
          date,
        );
        data[i]['basic'] = stats['basic']!;
        data[i]['overtime'] = stats['overtime']!;
        data[i]['night'] = stats['night']!;
      }

      // 「今日」かつ表示用データがある場合は最新を優先（リセット前用）
      if (i == now.weekday - 1 &&
          widget.member.attendanceTime != null &&
          widget.member.leaveTime != null) {
        final stats = _calculateStats(
          widget.member.attendanceTime,
          widget.member.leaveTime,
          date,
        );
        data[i]['basic'] = stats['basic']!;
        data[i]['overtime'] = stats['overtime']!;
        data[i]['night'] = stats['night']!;
      }
    }
    return data;
  }

  // 特定の打刻時間から実績を計算する
  Map<String, double> _calculateStats(
    String? attendanceTime,
    String? leaveTime,
    DateTime baseDate,
  ) {
    final start = _parseTime(attendanceTime, baseDate);
    var end = _parseTime(leaveTime, baseDate);
    if (start == null || end == null)
      return {'basic': 0.0, 'overtime': 0.0, 'night': 0.0};

    // 日を跨ぐ場合（退勤が翌日になる場合）の調整
    if (end.isBefore(start)) {
      end = end.add(const Duration(days: 1));
    }

    // 各帯域の重複時間を1分単位で計算
    // 基本時間（10:00 - 15:00）
    double basicHours = _getRangeOverlap(start, end, 10, 15);

    // 深夜料金（22:00 - 05:00） ※22:00-24:00 と 00:00-05:00 を合算
    double nightHours =
        _getRangeOverlap(start, end, 22, 24) +
        _getRangeOverlap(start, end, 24, 29);

    // 総労働時間
    double totalHours = end.difference(start).inMinutes / 60.0;

    // 時間外（総時間 - 基本時間 - 深夜時間）
    double overtimeHours = totalHours - basicHours - nightHours;
    if (overtimeHours < 0.001) overtimeHours = 0; // 浮動小数点の端数処理

    return {
      'basic': basicHours,
      'overtime': overtimeHours,
      'night': nightHours,
    };
  }

  // 1分単位で指定の範囲（hourStart - hourEnd）との重複時間を計算する
  double _getRangeOverlap(
    DateTime start,
    DateTime end,
    int hourStart,
    int hourEnd,
  ) {
    final baseDate = DateTime(start.year, start.month, start.day);
    final rangeStart = baseDate.add(Duration(hours: hourStart));
    final rangeEnd = baseDate.add(Duration(hours: hourEnd));

    final overlapStart = start.isAfter(rangeStart) ? start : rangeStart;
    final overlapEnd = end.isBefore(rangeEnd) ? end : rangeEnd;

    if (overlapStart.isBefore(overlapEnd)) {
      return overlapEnd.difference(overlapStart).inMinutes / 60.0;
    }
    return 0.0;
  }

  DateTime? _parseTime(String? timeStr, DateTime baseDate) {
    if (timeStr == null || timeStr.isEmpty) return null;
    try {
      final parts = timeStr.split(':');
      return DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    } catch (_) {
      return null;
    }
  }

  // 月間データの取得（member.workHistoryを参照）
  List<Map<String, dynamic>> get monthlyData {
    final int monthInt = int.parse(selectedMonth.replaceAll('月', ''));
    // 閏年などはDateTime(year, month + 1, 0).day で取得可能
    final daysInMonthCount = DateTime(selectedYear, monthInt + 1, 0).day;

    return List.generate(daysInMonthCount, (index) {
      int day = index + 1;
      final dateStr =
          "$selectedYear-${monthInt.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";

      double basic = 0.0;
      double overtime = 0.0;
      double night = 0.0;
      double leave = 0.0;

      // 履歴から取得
      final dayHistory = widget.member.workHistory[dateStr];
      if (dayHistory != null) {
        final stats = _calculateStats(
          dayHistory['attendanceTime'],
          dayHistory['leaveTime'],
          DateTime(selectedYear, monthInt, day),
        );
        basic = stats['basic']!;
        overtime = stats['overtime']!;
        night = stats['night']!;
      }

      // 有給休暇のチェック
      if (ShiftConfirmScreen.confirmedShifts[day] == 4) {
        leave = 4.0;
      }

      // 「今日」かつ表示用データがある場合は最新を優先（リセット前用）
      final now = DateTime.now();
      if (selectedYear == now.year &&
          monthInt == now.month &&
          day == now.day &&
          widget.member.attendanceTime != null &&
          widget.member.leaveTime != null) {
        final stats = _calculateStats(
          widget.member.attendanceTime,
          widget.member.leaveTime,
          now,
        );
        basic = stats['basic']!;
        overtime = stats['overtime']!;
        night = stats['night']!;
      }

      return {
        'basic': basic,
        'overtime': overtime,
        'night': night,
        'leave': leave,
      };
    });
  }

  // 出勤日の日数をカウント
  int get _attendanceCount {
    return weeklyData
        .where(
          (d) =>
              d['basic'] > 0 ||
              d['overtime'] > 0 ||
              d['night'] > 0 ||
              d['leave'] > 0,
        )
        .length;
  }

  int get _monthlyAttendanceCount {
    return monthlyData
        .where(
          (d) =>
              d['basic'] > 0 ||
              d['overtime'] > 0 ||
              d['night'] > 0 ||
              d['leave'] > 0,
        )
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final isWeekly = viewMode == '週間表示';

    return Scaffold(
      appBar: AppBar(title: Text(widget.member.name)),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFFFDFBF)],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 表示モード切り替えと月選択
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DropdownButton<String>(
                      value: viewMode,
                      items:
                          ['週間表示', '月間表示'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          viewMode = newValue!;
                        });
                      },
                    ),
                    if (!isWeekly)
                      DropdownButton<String>(
                        value: selectedMonth,
                        items:
                            availableMonths.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedMonth = newValue!;
                            // 年の調整（1月を選択した際に前年になるケースなどへの対応は簡易化のため現在の年に固定）
                            // 必要に応じてDateTimeから年を逆算することも可能
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                // 棒グラフ表示エリア
                Container(
                  color: Colors.white,
                  child: SizedBox(
                    height: 250,
                    child:
                        isWeekly ? _buildWeeklyChart() : _buildMonthlyChart(),
                  ),
                ),
                const SizedBox(height: 20),
                // Summary
                if (isWeekly) ...[
                  // 内訳ボックス（基本給、時間外、交通費など）
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                    ),
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '計${weeklyData.fold(0.0, (sum, item) => sum + (item['basic'] as double) + (item['overtime'] as double) + (item['night'] as double) + (item['leave'] as double)).toStringAsFixed(1)}時間',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          '基本時間10：00〜15：00',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        _buildBreakdownItem(
                          Colors.blue,
                          '基本給 1000×${weeklyData.fold(0.0, (sum, item) => sum + item['basic']).toStringAsFixed(1)}時間＝${(weeklyData.fold(0.0, (sum, item) => sum + (item['basic'] as double)) * 1000).toInt()}円',
                        ),
                        _buildBreakdownItem(
                          Colors.lightBlue,
                          '時間外 1250×${weeklyData.fold(0.0, (sum, item) => sum + item['overtime']).toStringAsFixed(1)}時間＝${(weeklyData.fold(0.0, (sum, item) => sum + (item['overtime'] as double)) * 1250).toInt()}円',
                        ),
                        _buildBreakdownItem(
                          const Color(0xFF98D8C8),
                          '深夜料金 1500×${weeklyData.fold(0.0, (sum, item) => sum + item['night']).toStringAsFixed(1)}時間＝${(weeklyData.fold(0.0, (sum, item) => sum + (item['night'] as double)) * 1500).toInt()}円',
                        ),
                        _buildBreakdownItem(
                          Colors.green,
                          '有給休暇 1000×${weeklyData.fold(0.0, (sum, item) => sum + item['leave']).toStringAsFixed(1)}時間＝${(weeklyData.fold(0.0, (sum, item) => sum + (item['leave'] as double)) * 1000).toInt()}円',
                        ),
                        const SizedBox(height: 20),
                        // Transportation
                        Row(
                          children: [
                            const Text('交通費'),
                            const SizedBox(width: 8),
                            const SizedBox(
                              width: 80,
                              child: TextField(
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.all(8),
                                  border: OutlineInputBorder(),
                                  hintText: '660',
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '円×$_attendanceCount＝${_attendanceCount * 660}円',
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text('有給休暇　残り2日', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  // 内訳ボックス（基本給、時間外、交通費など）
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                    ),
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '計${monthlyData.fold(0.0, (sum, item) => sum + (item['basic'] as double) + (item['overtime'] as double) + (item['night'] as double) + (item['leave'] as double)).toStringAsFixed(1)}時間',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildBreakdownItem(
                          Colors.blue,
                          '基本給 1000×${monthlyData.fold(0.0, (sum, item) => sum + item['basic']).toStringAsFixed(1)}時間＝${(monthlyData.fold(0.0, (sum, item) => sum + (item['basic'] as double)) * 1000).toInt()}円',
                        ),
                        _buildBreakdownItem(
                          Colors.lightBlue,
                          '時間外 1250×${monthlyData.fold(0.0, (sum, item) => sum + item['overtime']).toStringAsFixed(1)}時間＝${(monthlyData.fold(0.0, (sum, item) => sum + (item['overtime'] as double)) * 1250).toInt()}円',
                        ),
                        _buildBreakdownItem(
                          const Color(0xFF98D8C8),
                          '深夜料金 1500×${monthlyData.fold(0.0, (sum, item) => sum + item['night']).toStringAsFixed(1)}時間＝${(monthlyData.fold(0.0, (sum, item) => sum + (item['night'] as double)) * 1500).toInt()}円',
                        ),
                        _buildBreakdownItem(
                          Colors.green,
                          '有給休暇 1000×${monthlyData.fold(0.0, (sum, item) => sum + item['leave']).toStringAsFixed(1)}時間＝${(monthlyData.fold(0.0, (sum, item) => sum + (item['leave'] as double)) * 1000).toInt()}円',
                        ),
                        const SizedBox(height: 20),
                        // Transportation
                        Row(
                          children: [
                            const Text('交通費'),
                            const SizedBox(width: 8),
                            const SizedBox(
                              width: 80,
                              child: TextField(
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.all(8),
                                  border: OutlineInputBorder(),
                                  hintText: '660',
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '円×$_monthlyAttendanceCount＝${_monthlyAttendanceCount * 660}円',
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text('有給休暇　残り2日', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                // Calendar
                Center(
                  child: Text(
                    '${selectedYear}年$selectedMonth',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildCalendar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    double maxHours = 8.0;
    return Stack(
      children: [
        // Grid lines
        Positioned(
          left: 20,
          right: 0,
          top: 0,
          bottom: 20,
          child: CustomPaint(painter: GridPainter()),
        ),
        // Y-axis labels
        Positioned(
          left: 0,
          top: 0,
          bottom: 20,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('10', style: TextStyle(fontSize: 10)),
              const Text('8', style: TextStyle(fontSize: 10)),
              const Text('6', style: TextStyle(fontSize: 10)),
              const Text('4', style: TextStyle(fontSize: 10)),
              const Text('2', style: TextStyle(fontSize: 10)),
              const Text('0', style: TextStyle(fontSize: 10)),
            ],
          ),
        ),
        // Chart
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:
                weeklyData.map((data) {
                  double total =
                      data['basic'] +
                      data['overtime'] +
                      data['night'] +
                      data['leave'];
                  String tooltipText =
                      '基本給: ${data['basic']}h\n時間外: ${data['overtime']}h\n深夜: ${data['night']}h\n有給: ${data['leave']}h';

                  return Tooltip(
                    message: tooltipText,
                    child: GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('${data['day']}曜日の詳細'),
                              content: Text(
                                '基本給: ${data['basic']}時間\n'
                                '時間外: ${data['overtime']}時間\n'
                                '深夜料金: ${data['night']}時間\n'
                                '有給休暇: ${data['leave']}時間',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('閉じる'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (total > 0)
                              Container(
                                width: 40,
                                height: (total / maxHours) * 200,
                                child: Column(
                                  children: [
                                    if (data['leave'] > 0)
                                      Expanded(
                                        flex: (data['leave'] * 60).round(),
                                        child: Container(color: Colors.green),
                                      ),
                                    if (data['night'] > 0)
                                      Expanded(
                                        flex: (data['night'] * 60).round(),
                                        child: Container(
                                          color: const Color(0xFF98D8C8),
                                        ),
                                      ),
                                    if (data['overtime'] > 0)
                                      Expanded(
                                        flex: (data['overtime'] * 60).round(),
                                        child: Container(
                                          color: Colors.lightBlue,
                                        ),
                                      ),
                                    if (data['basic'] > 0)
                                      Expanded(
                                        flex: (data['basic'] * 60).round(),
                                        child: Container(color: Colors.blue),
                                      ),
                                  ],
                                ),
                              )
                            else
                              Container(width: 40, height: 10),
                            const SizedBox(height: 4),
                            Text(data['day']),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyChart() {
    double maxHours = 12.0;
    final displayDays = [1, 4, 7, 10, 13, 16, 19, 22, 25, 28, 30];

    return Stack(
      children: [
        // Grid lines
        Positioned(
          left: 20,
          right: 0,
          top: 0,
          bottom: 20,
          child: CustomPaint(painter: GridPainter()),
        ),
        // Y-axis labels
        Positioned(
          left: 0,
          top: 0,
          bottom: 20,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('10', style: TextStyle(fontSize: 10)),
              const Text('8', style: TextStyle(fontSize: 10)),
              const Text('6', style: TextStyle(fontSize: 10)),
              const Text('4', style: TextStyle(fontSize: 10)),
              const Text('2', style: TextStyle(fontSize: 10)),
              const Text('0', style: TextStyle(fontSize: 10)),
            ],
          ),
        ),
        // Chart
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(30, (index) {
              final data = monthlyData[index];
              final day = index + 1;
              double total =
                  data['basic'] +
                  data['overtime'] +
                  data['night'] +
                  data['leave'];
              String tooltipText =
                  '$day日\n基本給: ${data['basic']}h\n時間外: ${data['overtime']}h\n深夜: ${data['night']}h\n有給: ${data['leave']}h';

              return Expanded(
                child: Tooltip(
                  message: tooltipText,
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('$day日の詳細'),
                            content: Text(
                              '基本給: ${data['basic']}時間\n'
                              '時間外: ${data['overtime']}時間\n'
                              '深夜料金: ${data['night']}時間\n'
                              '有給休暇: ${data['leave']}時間',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('閉じる'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // 合計時間が0より大きい場合のみ、棒グラフを表示します
                            if (total > 0)
                              Container(
                                // 最大時間に対する割合でグラフの高さを決めます（最大200ピクセル）
                                height: (total / maxHours) * 200,
                                child: Column(
                                  children: [
                                    // 各項目の時間（有給、深夜など）に合わせて、色のついた部分の比率（flex）を決めます
                                    if (data['leave'] > 0)
                                      Expanded(
                                        flex: (data['leave'] * 60).round(),
                                        child: Container(color: Colors.green),
                                      ),
                                    if (data['night'] > 0)
                                      Expanded(
                                        flex: (data['night'] * 60).round(),
                                        child: Container(
                                          color: const Color(0xFF98D8C8),
                                        ),
                                      ),
                                    if (data['overtime'] > 0)
                                      Expanded(
                                        flex: (data['overtime'] * 60).round(),
                                        child: Container(
                                          color: Colors.lightBlue,
                                        ),
                                      ),
                                    if (data['basic'] > 0)
                                      Expanded(
                                        flex: (data['basic'] * 60).round(),
                                        child: Container(color: Colors.blue),
                                      ),
                                  ],
                                ),
                              )
                            else
                              // データがない場合は、高さ10ピクセルの空のスペースを表示します
                              Container(height: 10),
                            const SizedBox(height: 7),
                            SizedBox(
                              height: 8,
                              child:
                                  displayDays.contains(day)
                                      ? Text(
                                        '$day',
                                        style: const TextStyle(fontSize: 6),
                                      )
                                      : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(width: 16, height: 16, color: color),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  // 実績を表示するカレンダーウィジェットを作成する関数
  Widget _buildCalendar() {
    final int monthInt = int.parse(selectedMonth.replaceAll('月', ''));
    final firstDate = DateTime(selectedYear, monthInt, 1);
    final daysInMonth = DateTime(selectedYear, monthInt + 1, 0).day;
    final firstDayOfMonth = firstDate.weekday % 7; // 0=日, 1=月, ..., 6=土

    return Column(
      children: [
        // Weekday headers
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 7,
          childAspectRatio: 1.0,
          children: const [
            Center(
              child: Text(
                '日',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
            Center(
              child: Text('月', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Center(
              child: Text('火', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Center(
              child: Text('水', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Center(
              child: Text('木', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Center(
              child: Text('金', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Center(
              child: Text(
                '土',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Calendar grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: firstDayOfMonth + daysInMonth,
          itemBuilder: (context, index) {
            // Empty cells before the first day
            if (index < firstDayOfMonth) {
              return Container();
            }

            int day = index - firstDayOfMonth + 1;
            final dateStr =
                "$selectedYear-${monthInt.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
            // 履歴または現在の打刻があるか、あるいは有給休暇か
            final hasHistory = widget.member.workHistory.containsKey(dateStr);
            final isLeave = ShiftConfirmScreen.confirmedShifts[day] == 4;
            bool isAttendance = hasHistory || isLeave;
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isAttendance ? Colors.orange : Colors.grey[200],
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: isAttendance ? Colors.white : Colors.black,
                    fontWeight:
                        isAttendance ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.grey.withValues(alpha: 0.3)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    // Draw horizontal grid lines (0, 2, 4, 6, 8, 10 hours)
    for (int i = 0; i <= 5; i++) {
      double y = size.height - (size.height / 5 * i);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Shift Request Screen
// シフト希望表画面（カレンダータップで希望を入力）
class ShiftRequestScreen extends StatefulWidget {
  final Member member;

  const ShiftRequestScreen({super.key, required this.member});

  @override
  State<ShiftRequestScreen> createState() => _ShiftRequestScreenState();
}

// シフト希望表の状態管理クラス
class _ShiftRequestScreenState extends State<ShiftRequestScreen> {
  // 各日付の状態を保存するマップ（"YYYY-MM-DD" -> 状態ID）
  final Map<String, int> dayStates = {};
  final TextEditingController notesController = TextEditingController();

  late int selectedYear;
  late int selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedYear = now.year;
    selectedMonth = now.month;
  }

  // 利用可能な月のリストを取得（今月と来月）
  List<DateTime> get availableMonths {
    final now = DateTime.now();
    return [
      DateTime(now.year, now.month, 1),
      DateTime(now.year, now.month + 1, 1),
    ];
  }

  // 状態IDに応じた色を返す
  Color _getColorForState(int state) {
    switch (state) {
      case 1:
        return Colors.blue; // 出勤予定
      case 2:
        return Colors.lightBlue; // リモートワーク予定
      case 3:
        return const Color(0xFF98D8C8); // 出勤可能性あり (mint green)
      case 4:
        return Colors.green; // 有給休暇
      default:
        return Colors.grey[200]!;
    }
  }

  // 日付タップ時の処理（状態を切り替える）
  void _handleDayTap(int day) {
    final key =
        "$selectedYear-${selectedMonth.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
    setState(() {
      int currentState = dayStates[key] ?? 0;
      int nextState = (currentState + 1) % 5;
      if (nextState == 0) {
        dayStates.remove(key);
      } else {
        dayStates[key] = nextState;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.member.name} - シフト希望表')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFFFDFBF)],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month Selection Dropdown
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: DropdownButton<DateTime>(
                      value: DateTime(selectedYear, selectedMonth, 1),
                      underline: Container(),
                      items:
                          availableMonths.map((date) {
                            return DropdownMenuItem<DateTime>(
                              value: date,
                              child: Text(
                                '${date.year}年${date.month}月',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                      onChanged: (DateTime? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedYear = newValue.year;
                            selectedMonth = newValue.month;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Calendar
                _buildCalendar(),
                const SizedBox(height: 30),
                // 凡例（色の意味説明）
                // Legend Box
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey),
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '日付タップの回数で編集できます',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildLegendItem(
                        Colors.blue,
                        '出勤予定',
                        _getCountForState(1),
                      ),
                      _buildLegendItem(
                        Colors.lightBlue,
                        'リモートワーク予定',
                        _getCountForState(2),
                      ),
                      _buildLegendItem(
                        const Color(0xFF98D8C8),
                        '出勤可能性あり',
                        _getCountForState(3),
                      ),
                      _buildLegendItem(
                        Colors.green,
                        '有給休暇　残り2日',
                        _getCountForState(4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // 提出ボタン
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('確認'),
                              content: const Text('シフト希望を提出しました。'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '提出',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // 備考入力欄
                const Text(
                  '備考',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'メモを入力してください',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    final DateTime firstDay = DateTime(selectedYear, selectedMonth, 1);
    final int firstDayOfMonth = firstDay.weekday % 7; // 0=日, 1=月...
    final int daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;

    return Column(
      children: [
        // Weekday headers
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 7,
          childAspectRatio: 1.0,
          children: const [
            Center(
              child: Text(
                '日',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
            Center(
              child: Text('月', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Center(
              child: Text('火', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Center(
              child: Text('水', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Center(
              child: Text('木', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Center(
              child: Text('金', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Center(
              child: Text(
                '土',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Calendar grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: firstDayOfMonth + daysInMonth,
          itemBuilder: (context, index) {
            // Empty cells before the first day
            if (index < firstDayOfMonth) {
              return Container();
            }

            int day = index - firstDayOfMonth + 1;
            final key =
                "$selectedYear-${selectedMonth.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
            int state = dayStates[key] ?? 0;
            Color cellColor = _getColorForState(state);

            return GestureDetector(
              onTap: () => _handleDayTap(day),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: cellColor,
                  border: Border.all(color: Colors.grey[400]!, width: 1),
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: state > 0 ? Colors.white : Colors.black,
                      fontWeight:
                          state > 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  int _getCountForState(int state) {
    return dayStates.values.where((s) => s == state).length;
  }

  Widget _buildLegendItem(Color color, String text, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text('●：$text')),
          Text('$count日', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }
}

// Shift Confirmation Screen
// シフト確認画面（確定したシフトと目標を表示）
class ShiftConfirmScreen extends StatelessWidget {
  final Member member;

  const ShiftConfirmScreen({super.key, required this.member});

  // 確定シフトのダミーデータ（日付 -> 状態ID）
  static const Map<int, int> confirmedShifts = {
    1: 1,
    2: 1,
    3: 4,
    4: 1,
    5: 1,
    8: 2,
    9: 1,
    10: 1,
    11: 3,
    12: 1,
    15: 1,
    16: 1,
    17: 1,
    18: 1,
    19: 1,
    22: 1,
    23: 1,
    24: 1,
    25: 1,
    26: 1,
    29: 2,
    30: 1,
  };

  // 状態ごとの日数を計算する
  int _calculateShiftCount(int state) {
    return confirmedShifts.values.where((s) => s == state).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${member.name} - シフト確認')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFFFDFBF)],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Center(
                  child: Text(
                    '${DateTime.now().year}年${DateTime.now().month}月',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // 今月の目標表示
                const Text(
                  '今月の目標',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildGoalItem('１、イラストを完成させる。'),
                _buildGoalItem('２、勤務日数を増やす'),
                _buildGoalItem('３、こまめな報告、相談を。'),
                const SizedBox(height: 30),
                // カレンダー表示
                _buildCalendar(),
                const SizedBox(height: 30),
                // 凡例（色の意味説明）
                // Legend Box
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey),
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '凡例',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildLegendItem(
                        Colors.blue,
                        '出勤予定',
                        _calculateShiftCount(1),
                      ),
                      _buildLegendItem(
                        Colors.lightBlue,
                        'リモートワーク予定',
                        _calculateShiftCount(2),
                      ),
                      _buildLegendItem(
                        const Color(0xFF98D8C8),
                        '出勤可能性あり',
                        _calculateShiftCount(3),
                      ),
                      _buildLegendItem(
                        Colors.green,
                        '有給休暇　残り2日',
                        _calculateShiftCount(4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(text, style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _buildCalendar() {
    final DateTime now = DateTime.now();
    final DateTime firstDay = DateTime(now.year, now.month, 1);
    final int firstDayOfMonth = firstDay.weekday % 7; // 0=日, 1=月...
    final int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final int today = now.day;

    return Column(
      children: [
        // Weekday headers
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 7,
          childAspectRatio: 1.0,
          children: const [
            Center(
              child: Text(
                '日',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
            Center(
              child: Text('月', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Center(
              child: Text('火', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Center(
              child: Text('水', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Center(
              child: Text('木', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Center(
              child: Text('金', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Center(
              child: Text(
                '土',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Calendar grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: firstDayOfMonth + daysInMonth,
          itemBuilder: (context, index) {
            // Empty cells before the first day
            if (index < firstDayOfMonth) {
              return Container();
            }

            int day = index - firstDayOfMonth + 1;
            int state = confirmedShifts[day] ?? 0;
            bool isToday = day == today;

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: _getColorForState(state),
                border: Border.all(
                  color: isToday ? Colors.red : Colors.grey[400]!,
                  width: isToday ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: state > 0 ? Colors.white : Colors.black,
                    fontWeight:
                        state > 0 || isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getColorForState(int state) {
    switch (state) {
      case 1:
        return Colors.blue; // 出勤予定
      case 2:
        return Colors.lightBlue; // リモートワーク予定
      case 3:
        return const Color(0xFF98D8C8); // 出勤可能性あり (mint green)
      case 4:
        return Colors.green; // 有給休暇
      default:
        return Colors.grey[200]!;
    }
  }

  Widget _buildLegendItem(Color color, String text, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text('●：$text')),
          Text('$count日', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
