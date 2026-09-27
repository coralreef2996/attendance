import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_screen.dart';
import 'main.dart';

// ==========================================
// 管理者用画面 (勤怠管理)
// ==========================================

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  static const Color iconColor = Color(0xFF532900);
  static const Color gradientBaseColor = Color(0xFFFFDFBF);

  static final List<String> breakSpots = ['ソファー1', 'ソファー2', '和室スペース'];

  static final List<Member> members = [
    Member(
      name: '田中 太郎',
      job: 'イラスト',
      totalBreakTime: 60,
      elapsedBreakTime: 45,
      status: MemberStatus.working,
      icon: Icons.face,
      attendanceTime: '10:00',
      workMinutes: 240,
      breakMinutes: 60,
      remainingSeconds: 7200,
      isTimerActive: true,
      isWorkPhase: true,
      workHistory: Member.generateDummyWorkHistory(),
    ),
    Member(
      name: '佐藤 花子',
      job: 'DTM',
      totalBreakTime: 60,
      elapsedBreakTime: 30,
      status: MemberStatus.working,
      icon: Icons.face_3,
      attendanceTime: '09:55',
      workMinutes: 240,
      breakMinutes: 60,
      remainingSeconds: 5400,
      isTimerActive: true,
      isWorkPhase: true,
      workHistory: Member.generateDummyWorkHistory(),
    ),
    Member(
      name: '鈴木 一郎',
      job: '３Dモデリング',
      totalBreakTime: 60,
      elapsedBreakTime: 65,
      status: MemberStatus.overtime,
      icon: Icons.face_6,
      attendanceTime: '10:05',
      workMinutes: 240,
      breakMinutes: 60,
      remainingSeconds: -300,
      isTimerActive: true,
      isWorkPhase: false,
      isOverdue: true,
      workHistory: Member.generateDummyWorkHistory(),
    ),
    Member(
      name: '髙橋 美咲',
      job: 'イラスト',
      totalBreakTime: 60,
      elapsedBreakTime: 60,
      status: MemberStatus.onBreak,
      icon: Icons.face_2,
      attendanceTime: '10:00',
      workMinutes: 240,
      breakMinutes: 60,
      remainingSeconds: 0,
      isTimerActive: false,
      isWorkPhase: false,
      workHistory: Member.generateDummyWorkHistory(),
    ),
    Member(
      name: '佐々木 健一',
      job: '',
      totalBreakTime: 0,
      elapsedBreakTime: 0,
      status: MemberStatus.absent,
      icon: Icons.person_off,
      workHistory: Member.generateDummyWorkHistory(),
    ),
    Member(
      name: '山田 圭太',
      job: '',
      totalBreakTime: 0,
      elapsedBreakTime: 0,
      status: MemberStatus.absent,
      icon: Icons.person_off,
      workHistory: Member.generateDummyWorkHistory(),
    ),
  ];

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final GlobalKey<_PersonalDataTabState> _personalDataTabKey =
      GlobalKey<_PersonalDataTabState>();
  final GlobalKey<_AnalysisTabState> _analysisTabKey =
      GlobalKey<_AnalysisTabState>();
  final GlobalKey<_AppEditTabState> _appEditTabKey =
      GlobalKey<_AppEditTabState>();

  void _handleBack() {
    if (_personalDataTabKey.currentState?.handleBack() == true) {
      return;
    }
    if (_analysisTabKey.currentState?.handleBack() == true) {
      return;
    }
    if (_appEditTabKey.currentState?.handleBack() == true) {
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(
          appName: '勤怠管理',
          originalHome: AttendanceHomePage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: DefaultTabController(
        length: 4,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, AdminHomeScreen.gradientBaseColor],
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.white.withOpacity(0.9),
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: AdminHomeScreen.iconColor),
                tooltip: '戻る',
                onPressed: _handleBack,
              ),
              title: Text(
                '勤怠管理',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AdminHomeScreen.iconColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              bottom: TabBar(
                labelColor: AdminHomeScreen.iconColor,
                unselectedLabelColor: Colors.black54,
                indicatorColor: AdminHomeScreen.iconColor,
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 11,
                height: 1.1,
              ),
              tabs: [
                Tab(
                  icon: Icon(Icons.people_alt_outlined),
                  child: Text(
                    '個人データ\n一覧',
                    textAlign: TextAlign.center,
                  ),
                ),
                Tab(
                  icon: Icon(Icons.analytics_outlined),
                  child: Text(
                    '分析\n職員用メモ',
                    textAlign: TextAlign.center,
                  ),
                ),
                Tab(
                  icon: Icon(Icons.app_settings_alt_outlined),
                  child: Text(
                    '機能編集\n管理',
                    textAlign: TextAlign.center,
                  ),
                ),
                Tab(
                  icon: Icon(Icons.import_export_outlined),
                  child: Text(
                    '外部出力\n連携',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _PersonalDataTab(key: _personalDataTabKey, iconColor: AdminHomeScreen.iconColor),
              _AnalysisTab(key: _analysisTabKey, iconColor: AdminHomeScreen.iconColor),
              _AppEditTab(key: _appEditTabKey, iconColor: AdminHomeScreen.iconColor),
              const _ExportTab(iconColor: AdminHomeScreen.iconColor),
            ],
          ),
        ),
      ),
    ),
  );
}
}

class _AdminSubHeader extends StatelessWidget {
  final Color iconColor;
  const _AdminSubHeader({required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左上：「設定」ボタン
          OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: iconColor,
              side: BorderSide(color: iconColor.withOpacity(0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
            ),
            icon: const Icon(Icons.settings, size: 18),
            label: const Text('設定'),
          ),

          // 右上：「使い方」プルダウンメニューボタン
          PopupMenuButton<String>(
            color: Colors.white,
            surfaceTintColor: Colors.white,
            onSelected: (String value) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: iconColor,
                  content: Text(
                    '$value が選択されました',
                    style: const TextStyle(color: Colors.white),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: '使い方１',
                child: Text('使い方１', style: TextStyle(color: iconColor)),
              ),
              PopupMenuItem<String>(
                value: '使い方２',
                child: Text('使い方２', style: TextStyle(color: iconColor)),
              ),
              PopupMenuItem<String>(
                value: '使い方３',
                child: Text('使い方３', style: TextStyle(color: iconColor)),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: iconColor.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.help_outline,
                    size: 18,
                    color: iconColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '使い方',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: iconColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 1. 個人データ一覧 タブ
// ==========================================
class _PersonalDataTab extends StatefulWidget {
  final Color iconColor;
  const _PersonalDataTab({super.key, required this.iconColor});

  @override
  State<_PersonalDataTab> createState() => _PersonalDataTabState();
}

class _PersonalDataTabState extends State<_PersonalDataTab> {
  Member? _selectedMember;
  Member? _showWorkRecordForMember;
  Member? _showShiftConfirmForMember;

  List<Member> get _members => AdminHomeScreen.members;

  bool handleBack() {
    if (_showWorkRecordForMember != null) {
      setState(() {
        _showWorkRecordForMember = null;
      });
      return true;
    }
    if (_showShiftConfirmForMember != null) {
      setState(() {
        _showShiftConfirmForMember = null;
      });
      return true;
    }
    if (_selectedMember != null) {
      setState(() {
        _selectedMember = null;
      });
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return _buildTabContent(context);
  }

  Widget _buildTabContent(BuildContext context) {
    if (_showWorkRecordForMember != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: widget.iconColor),
                  onPressed: () {
                    setState(() {
                      _showWorkRecordForMember = null;
                    });
                  },
                ),
                Text(
                  '${_showWorkRecordForMember!.name} - 労働実績',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: widget.iconColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: WorkRecordScreen(
              member: _showWorkRecordForMember!,
              embed: true,
            ),
          ),
        ],
      );
    }

    if (_showShiftConfirmForMember != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: widget.iconColor),
                  onPressed: () {
                    setState(() {
                      _showShiftConfirmForMember = null;
                    });
                  },
                ),
                Text(
                  '${_showShiftConfirmForMember!.name} - シフト確認',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: widget.iconColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ShiftConfirmScreen(
              member: _showShiftConfirmForMember!,
              embed: true,
            ),
          ),
        ],
      );
    }

    if (_selectedMember != null) {
      return _buildMemberDetailMode(_selectedMember!);
    }

    int active = _members.where((m) => m.status != MemberStatus.absent && m.attendanceTime != null && m.leaveTime == null).length;
    int breakCount = _members.where((m) => m.status == MemberStatus.onBreak).length;
    int absentCount = _members.where((m) => m.status == MemberStatus.absent).length;
    int alertCount = _members.where((m) => m.isOverdue).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _AdminSubHeader(iconColor: widget.iconColor),
        
        // 勤怠ダッシュボード
        Card(
          color: Colors.white.withOpacity(0.9),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: widget.iconColor.withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.dashboard_outlined, color: widget.iconColor),
                    const SizedBox(width: 8),
                    Text(
                      '勤怠ダッシュボード',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: widget.iconColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('出勤中', '$active人', Colors.blue),
                    _buildStatItem('休憩中', '$breakCount人', Colors.orange),
                    _buildStatItem('アラート', '$alertCount件', Colors.red),
                    _buildStatItem('本日欠席', '$absentCount人', Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 個人データ一覧見出し
        Row(
          children: [
            Icon(Icons.people, color: widget.iconColor, size: 20),
            const SizedBox(width: 8),
            Text(
              '個人データ 一覧 (選択で閲覧モード起動)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: widget.iconColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // メンバーリスト
        ..._members.map((member) {
          String statusText = '出勤前';
          Color statusColor = Colors.grey;
          if (member.status == MemberStatus.absent) {
            statusText = '本日欠席';
            statusColor = Colors.black54;
          } else if (member.leaveTime != null) {
            statusText = '業務終了';
            statusColor = Colors.blueGrey;
          } else if (member.isOverdue) {
            statusText = '時間超過';
            statusColor = Colors.red;
          } else if (member.isTimerActive) {
            statusText = member.isWorkPhase ? '作業中' : '休憩中';
            statusColor = member.isWorkPhase ? Colors.blue : Colors.orange;
          } else if (member.attendanceTime != null) {
            statusText = member.status == MemberStatus.onBreak ? '休憩中' : '作業中';
            statusColor = member.status == MemberStatus.onBreak ? Colors.orange : Colors.blue;
          }

          return Card(
            color: Colors.white.withOpacity(0.9),
            margin: const EdgeInsets.symmetric(vertical: 4),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: widget.iconColor.withOpacity(0.1),
                child: Icon(member.icon, color: widget.iconColor),
              ),
              title: Text(
                member.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(member.job.isNotEmpty ? member.job : '職務未設定'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              onTap: () {
                setState(() {
                  _selectedMember = member;
                });
              },
            ),
          );
        }),
        const SizedBox(height: 16),

        // 休憩場所使用状況
        Card(
          color: Colors.white.withOpacity(0.9),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.coffee_outlined, color: widget.iconColor),
                    const SizedBox(width: 8),
                    const Text(
                      '休憩場所使用状況',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...List.generate(AdminHomeScreen.breakSpots.length, (index) {
                  final spotName = AdminHomeScreen.breakSpots[index];
                  final onBreakMembers = _members
                      .where((m) => m.status == MemberStatus.onBreak)
                      .toList();
                  
                  String statusText = '未使用';
                  Color statusColor = Colors.grey;
                  
                  if (index < onBreakMembers.length) {
                    statusText = '${onBreakMembers[index].name}　使用中';
                    statusColor = Colors.orange;
                  } else if (index == 0 && onBreakMembers.isEmpty) {
                    statusText = '田中 太郎　使用中';
                    statusColor = Colors.orange;
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          spotName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  // 個人メニュー読み取り (閲覧モード)
  Widget _buildMemberDetailMode(Member member) {
    double workingHoursProgress = 0.6;
    String remainingTo1500Text = '残り時間（2時間00分）';

    if (member.status == MemberStatus.absent) {
      workingHoursProgress = 0.0;
      remainingTo1500Text = '本日は出勤予定がありません';
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: widget.iconColor),
              onPressed: () {
                setState(() {
                  _selectedMember = null;
                });
              },
            ),
            Text(
              '${member.name} - 個人メニュー (閲覧モード)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: widget.iconColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 1. 勤務時間プログレスバー
        Card(
          color: Colors.white.withOpacity(0.9),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '■ 勤務時間プログレスバー (10:00 - 15:00)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: workingHoursProgress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(widget.iconColor),
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                ),
                const SizedBox(height: 8),
                Text(
                  remainingTo1500Text,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 1.5 休憩時間タイマー
        Card(
          color: Colors.white.withOpacity(0.9),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '■ 休憩時間タイマー',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '設定: ${member.workMinutes}分に一回${member.breakMinutes}分休憩',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: member.progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    member.isOverdue
                        ? Colors.red
                        : (member.isWorkPhase ? Colors.orange : Colors.grey[700]!),
                  ),
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                ),
                const SizedBox(height: 8),
                Text(
                  member.isTimerActive
                      ? '現在: ${member.isWorkPhase ? '作業中' : '休憩中'} (${member.isOverdue ? '時間超過' : '残り${member.remainingSeconds ~/ 60}分${(member.remainingSeconds % 60).toString().padLeft(2, '0')}秒'})'
                      : '現在: タイマー停止中',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 2. 本日の作業設定
        Card(
          color: Colors.white.withOpacity(0.9),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '■ 本日の作業設定',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: '設定中の作業',
                    labelStyle: TextStyle(color: widget.iconColor),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: const OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: member.job.isNotEmpty ? member.job : '未設定'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 3. 労働実績の確認
        Card(
          color: Colors.white.withOpacity(0.9),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '■ 労働実績の確認',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1週間の合計時間　：　(${_getWeeklyTotalHours(member).toStringAsFixed(1)}時間)',
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.iconColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _showWorkRecordForMember = member;
                        });
                      },
                      child: const Text('グラフを表示'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 4. 個人のシフト確認、シフト希望表の閲覧
        Builder(
          builder: (context) {
            final now = DateTime.now();
            final monday = now.subtract(Duration(days: now.weekday - 1));
            final tues = monday.add(const Duration(days: 1));
            final wed = monday.add(const Duration(days: 2));
            final thurs = monday.add(const Duration(days: 3));
            final fri = monday.add(const Duration(days: 4));
            final sat = monday.add(const Duration(days: 5));
            final sun = monday.add(const Duration(days: 6));

            return Card(
              color: Colors.white.withOpacity(0.9),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '■ シフト',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Table(
                      border: TableBorder.all(color: Colors.grey.withOpacity(0.3)),
                      children: [
                        const TableRow(
                          decoration: BoxDecoration(color: Color(0xFFF5F5F5)),
                          children: [
                            TableCell(child: Center(child: Padding(padding: EdgeInsets.all(6), child: Text('月')))),
                            TableCell(child: Center(child: Padding(padding: EdgeInsets.all(6), child: Text('火')))),
                            TableCell(child: Center(child: Padding(padding: EdgeInsets.all(6), child: Text('水')))),
                            TableCell(child: Center(child: Padding(padding: EdgeInsets.all(6), child: Text('木')))),
                            TableCell(child: Center(child: Padding(padding: EdgeInsets.all(6), child: Text('金')))),
                            TableCell(child: Center(child: Padding(padding: EdgeInsets.all(6), child: Text('土')))),
                            TableCell(child: Center(child: Padding(padding: EdgeInsets.all(6), child: Text('日')))),
                          ],
                        ),
                        TableRow(
                          children: [
                            TableCell(child: Center(child: Padding(padding: const EdgeInsets.all(6), child: Text(_getShiftStatusForDay(monday))))),
                            TableCell(child: Center(child: Padding(padding: const EdgeInsets.all(6), child: Text(_getShiftStatusForDay(tues))))),
                            TableCell(child: Center(child: Padding(padding: const EdgeInsets.all(6), child: Text(_getShiftStatusForDay(wed))))),
                            TableCell(child: Center(child: Padding(padding: const EdgeInsets.all(6), child: Text(_getShiftStatusForDay(thurs))))),
                            TableCell(child: Center(child: Padding(padding: const EdgeInsets.all(6), child: Text(_getShiftStatusForDay(fri))))),
                            TableCell(child: Center(child: Padding(padding: const EdgeInsets.all(6), child: Text(_getShiftStatusForDay(sat))))),
                            TableCell(child: Center(child: Padding(padding: const EdgeInsets.all(6), child: Text(_getShiftStatusForDay(sun))))),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'シフト希望ステータス: 希望通り（週3日出勤・土日祝休み）で確定済',
                      style: TextStyle(fontSize: 12, color: widget.iconColor, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.iconColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _showShiftConfirmForMember = member;
                        });
                      },
                      child: const Text('今月のシフト表'),
                    ),
                  ],
                ),
              ),
            );
          }
        ),
      ],
    );
  }

  Widget _buildStampTimeBox(String label, String time) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            time,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
        ),
      ],
    );
  }

  double _getWeeklyTotalHours(Member member) {
    double total = 0.0;
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: now.weekday - 1 - i));
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      double basic = 0.0;
      double overtime = 0.0;
      double night = 0.0;
      double leave = 0.0;

      if (ShiftConfirmScreen.confirmedShifts[date.day] == 4) {
        leave = 4.0;
      }

      final dayHistory = member.workHistory[dateStr];
      if (dayHistory != null) {
        final stats = _calculateMemberStats(
          dayHistory['attendanceTime'],
          dayHistory['leaveTime'],
          date,
        );
        basic = stats['basic']!;
        overtime = stats['overtime']!;
        night = stats['night']!;
      }

      if (i == now.weekday - 1 &&
          member.attendanceTime != null &&
          member.leaveTime != null) {
        final stats = _calculateMemberStats(
          member.attendanceTime,
          member.leaveTime,
          date,
        );
        basic = stats['basic']!;
        overtime = stats['overtime']!;
        night = stats['night']!;
      }
      total += basic + overtime + night + leave;
    }
    return total;
  }

  Map<String, double> _calculateMemberStats(
    String? attendanceTime,
    String? leaveTime,
    DateTime baseDate,
  ) {
    final start = _parseTimeHelper(attendanceTime, baseDate);
    var end = _parseTimeHelper(leaveTime, baseDate);
    if (start == null || end == null) {
      return {'basic': 0.0, 'overtime': 0.0, 'night': 0.0};
    }

    if (end.isBefore(start)) {
      end = end.add(const Duration(days: 1));
    }

    double basicHours = _getRangeOverlapHelper(start, end, 10, 15);
    double nightHours =
        _getRangeOverlapHelper(start, end, 22, 24) +
        _getRangeOverlapHelper(start, end, 24, 29);

    double totalHours = end.difference(start).inMinutes / 60.0;
    double overtimeHours = totalHours - basicHours - nightHours;
    if (overtimeHours < 0.001) overtimeHours = 0;

    return {
      'basic': basicHours,
      'overtime': overtimeHours,
      'night': nightHours,
    };
  }

  double _getRangeOverlapHelper(
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

  DateTime? _parseTimeHelper(String? timeStr, DateTime baseDate) {
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

  String _getShiftStatusForDay(DateTime date) {
    final state = ShiftConfirmScreen.confirmedShifts[date.day];
    switch (state) {
      case 1:
        return '出勤';
      case 2:
        return 'リモ';
      case 3:
        return '未定';
      case 4:
        return '有給';
      default:
        return '休み';
    }
  }
}

// ==========================================
// 2. 分析・職員用メモ タブ
// ==========================================
class _AnalysisTab extends StatefulWidget {
  final Color iconColor;
  const _AnalysisTab({super.key, required this.iconColor});

  @override
  State<_AnalysisTab> createState() => _AnalysisTabState();
}

class _AnalysisTabState extends State<_AnalysisTab> {
  bool _showAdminMemos = false;

  bool handleBack() {
    if (_showAdminMemos) {
      setState(() {
        _showAdminMemos = false;
      });
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_showAdminMemos) {
      return AdminAttendanceMemosScreen(
        iconColor: widget.iconColor,
        onBack: () {
          setState(() {
            _showAdminMemos = false;
          });
        },
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _AdminSubHeader(iconColor: widget.iconColor),
        const SizedBox(height: 12),

        // 管理者用メモ（最優先・データ分析の要）
        Card(
          color: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: widget.iconColor.withValues(alpha: 0.35), width: 1.5),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.iconColor.withValues(alpha: 0.08),
                  Colors.white,
                ],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: widget.iconColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.analytics_outlined, color: widget.iconColor, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '管理者用メモ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: widget.iconColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade700,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '分析の要',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'AI分析・個別支援データ蓄積と記録',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.iconColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 46),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _showAdminMemos = true;
                    });
                  },
                  icon: const Icon(Icons.note_alt_outlined, size: 20),
                  label: const Text(
                    '勤怠メモ表示',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 「案内ひろば」AI分析のヒント（管理者用メモの真下に配置）
        _buildSupportHubPromptCard(
          context: context,
          iconColor: widget.iconColor,
          crossAppPrompts: [
            '出勤率・遅刻と、体調記録（HP）や睡眠不足タグの関連性を分析して',
            '突発休や遅刻が多い日の前日に、簡易連絡（チャット）でどんな相談があったか調べて',
            '安定して出勤できている時の作業内容（得意な作業）を特定して、来月のシフト案を作って',
          ],
          singleAppPrompts: [
            '直近1ヶ月で遅刻や離席が増えている曜日や時間帯の傾向を教えて',
            '連続勤務が続いた時の勤怠安定度スコアの変化と、必要な休息日数を提案して',
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSupportHubPromptCard({
    required BuildContext context,
    required Color iconColor,
    required List<String> crossAppPrompts,
    required List<String> singleAppPrompts,
  }) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: iconColor.withValues(alpha: 0.25), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.lightbulb_outline, color: Colors.amber.shade900, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '「案内ひろば」AI分析のヒント',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, size: 11, color: Colors.blue.shade800),
                            const SizedBox(width: 3),
                            Text(
                              'Gemini連携',
                              style: TextStyle(
                                color: Colors.blue.shade800,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'マスターアプリ「案内ひろば」のAIにこう聞いてみよう！（タップでコピー）',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.link, size: 15, color: iconColor),
                const SizedBox(width: 4),
                Text(
                  '他のデータと掛け合わせて分析',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...crossAppPrompts.map((prompt) => _buildPromptItem(context, prompt, iconColor)),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.search, size: 15, color: iconColor),
                const SizedBox(width: 4),
                Text(
                  'このアプリのデータを深掘り分析',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...singleAppPrompts.map((prompt) => _buildPromptItem(context, prompt, iconColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptItem(BuildContext context, String prompt, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Material(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Clipboard.setData(ClipboardData(text: prompt));
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '質問文をコピーしました！「案内ひろば」で貼り付けて使えます',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF1E293B),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1.0),
                  child: Icon(Icons.chat_bubble_outline, size: 14, color: iconColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    prompt,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.copy_rounded, size: 14, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 3. 機能編集・管理 タブ
// ==========================================
class _AppEditTab extends StatefulWidget {
  final Color iconColor;
  const _AppEditTab({super.key, required this.iconColor});

  @override
  State<_AppEditTab> createState() => _AppEditTabState();
}

class _AppEditTabState extends State<_AppEditTab> {
  bool _isShiftRecruiting = true;
  String _maxShiftDays = '15';
  Member? _showShiftRequestForMember;
  String? _selectedShiftUserName;

  final TextEditingController _baseWageController = TextEditingController(text: '1100');
  final TextEditingController _breakWageController = TextEditingController(text: '0');

  List<String> get _breakSpots => AdminHomeScreen.breakSpots;

  bool handleBack() {
    if (_showShiftRequestForMember != null) {
      setState(() {
        _showShiftRequestForMember = null;
      });
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_showShiftRequestForMember != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: widget.iconColor),
                  onPressed: () {
                    setState(() {
                      _showShiftRequestForMember = null;
                    });
                  },
                ),
                Text(
                  '${_showShiftRequestForMember!.name} - シフト受付',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: widget.iconColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ShiftRequestScreen(
              member: _showShiftRequestForMember!,
              embed: true,
              isAdminMode: true,
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _AdminSubHeader(iconColor: widget.iconColor),

        // シフト受付
        Card(
          color: Colors.white.withOpacity(0.9),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_month_outlined, color: widget.iconColor),
                    const SizedBox(width: 8),
                    const Text(
                      'シフト受付',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('来月のシフト希望の受付を開始する', style: TextStyle(fontSize: 13)),
                  activeColor: widget.iconColor,
                  value: _isShiftRecruiting,
                  onChanged: (val) => setState(() => _isShiftRecruiting = val),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '利用者一覧',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.8),
                        ),
                        isExpanded: true,
                        value: _selectedShiftUserName ?? AdminHomeScreen.members.first.name,
                        items: AdminHomeScreen.members.map((member) {
                          return DropdownMenuItem<String>(
                            value: member.name,
                            child: Text(member.name),
                          );
                        }).toList(),
                        onChanged: (String? newVal) {
                          setState(() {
                            _selectedShiftUserName = newVal;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.iconColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        final selectedName = _selectedShiftUserName ?? AdminHomeScreen.members.first.name;
                        final member = AdminHomeScreen.members.firstWhere((m) => m.name == selectedName);
                        setState(() {
                          _showShiftRequestForMember = member;
                        });
                      },
                      child: const Text('シフト受付'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 時給設定、休憩時間時給設定
        Card(
          color: Colors.white.withOpacity(0.9),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.payments_outlined, color: widget.iconColor),
                    const SizedBox(width: 8),
                    const Text(
                      '時給・休憩時給設定',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _baseWageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '基本時給 (円)',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _breakWageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '休憩時間時給 (円)',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.iconColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('時給設定を保存しました')),
                        );
                      },
                      child: const Text('時給設定を保存'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 休憩場所の設定
        Card(
          color: Colors.white.withOpacity(0.9),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.chair_outlined, color: widget.iconColor),
                    const SizedBox(width: 8),
                    const Text(
                      '休憩場所の設定',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._breakSpots.map((spot) => ListTile(
                      dense: true,
                      title: Text(spot),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _breakSpots.remove(spot);
                          });
                        },
                      ),
                    )),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: widget.iconColor,
                          side: BorderSide(color: widget.iconColor),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('休憩場所を追加する'),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              final controller = TextEditingController();
                              return AlertDialog(
                                title: const Text('休憩場所を追加'),
                                content: TextField(
                                  controller: controller,
                                  decoration: const InputDecoration(hintText: '休憩室C など'),
                                ),
                                actions: [
                                  TextButton(
                                    child: const Text('キャンセル'),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  TextButton(
                                    child: const Text('追加'),
                                    onPressed: () {
                                      if (controller.text.isNotEmpty) {
                                        setState(() {
                                          _breakSpots.add(controller.text);
                                        });
                                      }
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 4. 外部出力・連携 タブ
// ==========================================
class _ExportTab extends StatefulWidget {
  final Color iconColor;
  const _ExportTab({required this.iconColor});

  @override
  State<_ExportTab> createState() => _ExportTabState();
}

class _ExportTabState extends State<_ExportTab> {
  bool _isLineLinked = true;
  bool _isSlackLinked = false;
  bool _isGoogleCalendarLinked = true;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _AdminSubHeader(iconColor: widget.iconColor),

        // チャットアプリ通知連携 / 外部チャットアプリ連携(LINE、スラックなど)
        Card(
          color: Colors.white.withOpacity(0.9),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, color: widget.iconColor),
                    const SizedBox(width: 8),
                    const Text(
                      '外部チャットアプリ連携 (LINE, Slack等)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('LINE 連携 (職員用の遅刻・緊急アラート通知)', style: TextStyle(fontSize: 13)),
                  subtitle: Text(_isLineLinked ? '現在連携中 (グループトークン: 設定済)' : '未連携', style: const TextStyle(fontSize: 11)),
                  activeColor: widget.iconColor,
                  value: _isLineLinked,
                  onChanged: (val) => setState(() => _isLineLinked = val),
                ),
                SwitchListTile(
                  title: const Text('Slack 連携 (#attendance-feed で自動朝点呼通知)', style: TextStyle(fontSize: 13)),
                  subtitle: Text(_isSlackLinked ? '現在連携中 (Webhook URL: 設定済)' : '未連携', style: const TextStyle(fontSize: 11)),
                  activeColor: widget.iconColor,
                  value: _isSlackLinked,
                  onChanged: (val) => setState(() => _isSlackLinked = val),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: widget.iconColor,
                        side: BorderSide(color: widget.iconColor),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('LINE/Slack へのテスト送信に成功しました。')),
                        );
                      },
                      child: const Text('連携テスト送信'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 勤怠実績データのエクスポートcsvやpdfなど
        Card(
          color: Colors.white.withOpacity(0.9),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.download_for_offline_outlined, color: widget.iconColor),
                    const SizedBox(width: 8),
                    const Text(
                      '勤怠実績データ エクスポート',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('出力形式を選択して、外部ソフト(freeeやMFクラウド)へ同期、またはPDFをダウンロードします。', style: TextStyle(fontSize: 12, color: Colors.black87)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: widget.iconColor,
                          side: BorderSide(color: widget.iconColor),
                        ),
                        icon: const Icon(Icons.file_present),
                        label: const Text('freee連携 (CSV)'),
                        onPressed: () => _showExportSuccess('freee向け CSV'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: widget.iconColor,
                          side: BorderSide(color: widget.iconColor),
                        ),
                        icon: const Icon(Icons.file_copy),
                        label: const Text('MFクラウド連携 (CSV)'),
                        onPressed: () => _showExportSuccess('マネーフォワード向け CSV'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.iconColor,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('全従業員の勤怠実績PDFをダウンロード'),
                        onPressed: () => _showExportSuccess('全実績PDF'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // シフトカレンダーの外部連携(Googleカレンダーなど)
        Card(
          color: Colors.white.withOpacity(0.9),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.sync, color: widget.iconColor),
                    const SizedBox(width: 8),
                    const Text(
                      'シフトカレンダー外部連携',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Google カレンダーに自動で同期する', style: TextStyle(fontSize: 13)),
                  subtitle: const Text('最終同期: 10分前 (正常終了)', style: TextStyle(fontSize: 11)),
                  activeColor: widget.iconColor,
                  value: _isGoogleCalendarLinked,
                  onChanged: (val) => setState(() => _isGoogleCalendarLinked = val),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showExportSuccess(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: widget.iconColor,
        content: Text('$type データを出力・エクスポートしました。'),
      ),
    );
  }
}

// ==========================================
// 勤怠管理 管理者用メモ画面
// ==========================================

class AttendanceMemo {
  final String id;
  final String userName;
  final DateTime dateTime;
  final String stability;
  final String situation;
  final String consideration;
  final String notes;

  AttendanceMemo({
    required this.id,
    required this.userName,
    required this.dateTime,
    required this.stability,
    required this.situation,
    required this.consideration,
    required this.notes,
  });
}

class AdminAttendanceMemosScreen extends StatefulWidget {
  final Color iconColor;
  final VoidCallback onBack;

  const AdminAttendanceMemosScreen({
    super.key,
    required this.iconColor,
    required this.onBack,
  });

  @override
  State<AdminAttendanceMemosScreen> createState() => _AdminAttendanceMemosScreenState();
}

class _AdminAttendanceMemosScreenState extends State<AdminAttendanceMemosScreen> {
  static final List<AttendanceMemo> _memos = [
    AttendanceMemo(
      id: '1',
      userName: '田中 太郎',
      dateTime: DateTime.now().subtract(const Duration(hours: 2)),
      stability: '◎ 非常に安定',
      situation: '時間通りに出退勤・自律休憩',
      consideration: '特になし',
      notes: '本日も時間通りに出勤し、集中して作業を実施。休憩も自発的に取得できていた。',
    ),
    AttendanceMemo(
      id: '2',
      userName: '鈴木 一郎',
      dateTime: DateTime.now().subtract(const Duration(hours: 5)),
      stability: '△ やや不安定(遅刻/早退)',
      situation: '休憩の促し・声かけを実施',
      consideration: '朝の声かけ強化',
      notes: '午後の休憩が長引く傾向があったため声かけを実施。体調自体は良好とのこと。',
    ),
  ];

  String? _selectedFilterUser;

  String _inputUserName = '田中 太郎';
  String _selectedStability = '◎ 非常に安定';
  String _selectedSituation = '時間通りに出退勤・自律休憩';
  String _selectedConsideration = '特になし';
  final TextEditingController _notesController = TextEditingController();
  DateTime _inputDateTime = DateTime.now();

  static const List<String> _userList = [
    '田中 太郎',
    '佐藤 花子',
    '鈴木 一郎',
    '髙橋 美咲',
    '佐々木 健一',
    '山田 圭太',
  ];

  static const List<String> _stabilities = [
    '◎ 非常に安定',
    '◯ 安定',
    '△ やや不安定(遅刻/早退)',
    '▲ 突発休あり',
  ];

  static const List<String> _situations = [
    '時間通りに出退勤・自律休憩',
    '休憩の促し・声かけを実施',
    '疲労による中抜け・早退',
    '残業・時間外対応',
  ];

  static const List<String> _considerations = [
    '特になし',
    '短縮勤務を検討',
    '朝の声かけ強化',
    '業務量調整',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}年${dt.month}月${dt.day}日 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedFilterUser == null
        ? _memos
        : _memos.where((m) => m.userName == _selectedFilterUser).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ヘッダー（戻るボタン）
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: widget.iconColor),
              onPressed: widget.onBack,
            ),
            Text(
              '【管理】勤怠メモ (閲覧/代理記録)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: widget.iconColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 新規メモ作成カード
        Card(
          color: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit_note, color: widget.iconColor),
                    const SizedBox(width: 8),
                    Text(
                      '勤怠メモを記録する',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: widget.iconColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // メモ対象者
                DropdownButtonFormField<String>(
                  value: _inputUserName,
                  decoration: const InputDecoration(
                    labelText: 'メモ対象者',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: _userList
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _inputUserName = val);
                  },
                ),
                const SizedBox(height: 16),

                // 勤怠安定度
                const Text(
                  '勤怠安定度',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _stabilities.map((s) {
                    final isSelected = _selectedStability == s;
                    return ChoiceChip(
                      label: Text(s, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
                      selected: isSelected,
                      selectedColor: widget.iconColor,
                      onSelected: (val) {
                        if (val) setState(() => _selectedStability = s);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // 出退勤・休憩の状況
                DropdownButtonFormField<String>(
                  value: _selectedSituation,
                  decoration: const InputDecoration(
                    labelText: '出退勤・休憩の状況',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _situations
                      .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSituation = val);
                  },
                ),
                const SizedBox(height: 16),

                // 次回への配慮事項
                const Text(
                  '次回への配慮事項',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _considerations.map((c) {
                    final isSelected = _selectedConsideration == c;
                    return ChoiceChip(
                      label: Text(c, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
                      selected: isSelected,
                      selectedColor: widget.iconColor,
                      onSelected: (val) {
                        if (val) setState(() => _selectedConsideration = c);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // 補足メモ
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: '補足・特記事項（任意）',
                    hintText: '例：午後の休憩時間について声かけを実施',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // 日時選択 ＆ 保存ボタン
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _inputDateTime,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (pickedDate != null) {
                            if (!context.mounted) return;
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(_inputDateTime),
                            );
                            if (pickedTime != null) {
                              setState(() {
                                _inputDateTime = DateTime(
                                  pickedDate.year,
                                  pickedDate.month,
                                  pickedDate.day,
                                  pickedTime.hour,
                                  pickedTime.minute,
                                );
                              });
                            }
                          }
                        },
                        icon: const Icon(Icons.calendar_month, size: 18),
                        label: Text(
                          _formatDateTime(_inputDateTime),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.iconColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: () {
                        final newMemo = AttendanceMemo(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          userName: _inputUserName,
                          dateTime: _inputDateTime,
                          stability: _selectedStability,
                          situation: _selectedSituation,
                          consideration: _selectedConsideration,
                          notes: _notesController.text,
                        );
                        setState(() {
                          _memos.insert(0, newMemo);
                          _notesController.clear();
                          _inputDateTime = DateTime.now();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: widget.iconColor,
                            content: Text('$_inputUserName の勤怠メモを保存しました'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text('保存する'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),

        // 絞り込みフィルター
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                value: _selectedFilterUser,
                decoration: const InputDecoration(
                  labelText: '利用者で絞り込む',
                  isDense: true,
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.filter_list),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('すべての利用者'),
                  ),
                  ..._userList.map(
                    (u) => DropdownMenuItem<String?>(
                      value: u,
                      child: Text(u),
                    ),
                  ),
                ],
                onChanged: (val) => setState(() => _selectedFilterUser = val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 過去メモ一覧
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                '記録されたメモはありません',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...filtered.map((memo) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: Colors.white.withValues(alpha: 0.95),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person, size: 18, color: Colors.blueGrey),
                            const SizedBox(width: 4),
                            Text(
                              memo.userName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                          onPressed: () {
                            setState(() {
                              _memos.removeWhere((m) => m.id == memo.id);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('メモを削除しました')),
                            );
                          },
                          tooltip: '削除',
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: widget.iconColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: widget.iconColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            memo.stability,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: widget.iconColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            memo.situation,
                            style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '配慮: ${memo.consideration}',
                            style: const TextStyle(fontSize: 11, color: Colors.brown),
                          ),
                        ),
                      ],
                    ),
                    if (memo.notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        memo.notes,
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      _formatDateTime(memo.dateTime),
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

