import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/moods.dart';
import '../../core/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/api_service.dart';
import '../../services/mood_service.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/leaf_background.dart';
import '../../widgets/mood_emoji.dart';

// Chart sizes (the emoji column lines up with the chart rows)
const double _plotHeight = 280;   // height of the drawing area
const double _bottomLabels = 44;  // space for the day labels underneath

class MoodChartScreen extends StatefulWidget {
  const MoodChartScreen({super.key});

  @override
  State<MoodChartScreen> createState() => _MoodChartScreenState();
}

class _MoodChartScreenState extends State<MoodChartScreen> {
  int _days = 7; // 7 or 30
  List<ChartPoint> _points = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final points = await MoodService.instance.getChart(_days);
      if (!mounted) return;
      setState(() {
        _points = points;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _switchDays(int days) {
    if (days == _days) return;
    setState(() => _days = days);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // -1 = no tab selected (this page is opened from History)
      bottomNavigationBar: const AppBottomNav(currentIndex: -1),
      body: LeafBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 20),
              _toggle(),
              const SizedBox(height: 28),
              _chartCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Back arrow + logo + "Your Mood" ----------
  Widget _header() {
    return Stack(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        const Align(
          alignment: Alignment.topRight,
          child: AppLogo(height: 100),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 120, left: 20),
          child: Text(
            'Your Mood',
            style: AppTextStyles.heading.copyWith(fontSize: 40),
          ),
        ),
      ],
    );
  }

  // ---------- "7 days" / "30 days" buttons ----------
  Widget _toggle() {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Row(
        children: [
          _toggleButton('7 days', 7),
          const SizedBox(width: 8),
          _toggleButton('30 days', 30),
        ],
      ),
    );
  }

  Widget _toggleButton(String text, int days) {
    final selected = _days == days;
    return GestureDetector(
      onTap: () => _switchDays(days),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 120,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF8DB54B) : const Color(0xFFEDE8E8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? const Color(0xFF8DB54B) : AppColors.lightGreenBorder,
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 18,
            color: selected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  // ---------- The white card with the chart ----------
  Widget _chartCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 20, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.lightGreenBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: _plotHeight + _bottomLabels,
            child: _chartBody(),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.history),
            child: Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Text(
                'Notice a pattern? Check your history.',
                style: AppTextStyles.body.copyWith(
                  fontSize: 15,
                  color: AppColors.mediumGreen,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center, style: AppTextStyles.body),
            TextButton(onPressed: _load, child: const Text('Try again')),
          ],
        ),
      );
    }

    final hasData = _points.any((p) => p.average != null);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _emojiColumn(),
        Expanded(
          child: hasData
              ? _lineChart()
              : Center(
                  child: Text(
                    'No moods logged in the last $_days days.\nLog one on Home 🌿',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.greyBody,
                  ),
                ),
        ),
      ],
    );
  }

  // ---------- Left column: 5 mood emojis, top = best ----------
  Widget _emojiColumn() {
    return SizedBox(
      width: 100,
      height: _plotHeight,
      child: Column(
        children: AppMoods.byScoreDesc
            .map(
              (mood) => Expanded(
                child: Row(
                  children: [
                    MoodEmoji(mood: mood, size: 34),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        mood.label,
                        style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ---------- The line chart ----------
  Widget _lineChart() {
    // One dot per day that has a mood (days without entries are skipped)
    final spots = <FlSpot>[];
    for (var i = 0; i < _points.length; i++) {
      final avg = _points[i].average;
      if (avg != null) spots.add(FlSpot(i.toDouble(), avg));
    }

    const gridColor = Color(0xFFE0E0E0);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (_points.length - 1).toDouble(),
        // 0.5 → 5.5 so each mood row lines up with its emoji
        minY: 0.5,
        maxY: 5.5,
        lineTouchData: const LineTouchData(enabled: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: _days == 7 ? 1 : 5,
          getDrawingHorizontalLine: (_) => const FlLine(color: gridColor, strokeWidth: 1),
          getDrawingVerticalLine: (_) => const FlLine(color: gridColor, strokeWidth: 1),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            left: BorderSide(color: gridColor),
            bottom: BorderSide(color: gridColor),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: _bottomLabels,
              interval: 1,
              getTitlesWidget: (value, meta) => _dayLabel(value),
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: AppColors.darkGreen,
            barWidth: 2,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 4,
                color: AppColors.darkGreen,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  // 7 days: "Mon / 16"   ·   30 days: "16 / Nov" (every 5th day only)
  Widget _dayLabel(double value) {
    final i = value.toInt();
    if (value != i.toDouble() || i < 0 || i >= _points.length) {
      return const SizedBox.shrink();
    }
    if (_days == 30 && i % 5 != 0 && i != _points.length - 1) {
      return const SizedBox.shrink();
    }

    final date = _points[i].date;
    final top = _days == 7
        ? DateFormat('EEE').format(date)   // Mon
        : DateFormat('d').format(date);    // 16
    final bottom = _days == 7
        ? DateFormat('d').format(date)     // 16
        : DateFormat('MMM').format(date);  // Nov

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        '$top\n$bottom',
        textAlign: TextAlign.center,
                style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black,
          height: 1.3,
        ),
      ),
    );
  }
}