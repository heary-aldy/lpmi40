# 📊 Bible Reading Tracking - Premium Feature

## 🎯 **Feature Overview**

**Purpose:** Comprehensive Bible reading progress tracking and analytics  
**Target Users:** Premium subscribers seeking structured Bible study  
**Integration:** Works seamlessly with Bible reading and AI chat features  
**Gamification:** Achievement system to encourage consistent reading  

---

## 📈 **Core Tracking Features**

### **1. Reading Progress Tracking**
```dart
class BibleReadingProgress {
  final String userId;
  final DateTime date;
  final String bookName;           // "Kejadian", "Matius"
  final int chapter;               // Chapter number
  final List<int> versesRead;      // Individual verses read
  final Duration readingTime;      // Time spent reading
  final int wordsRead;             // Estimated word count
  final bool completedChapter;     // Did user finish the chapter?
  final ReadingMethod method;      // Sequential, topical, plan-based
  final String? notes;             // Personal notes
  final List<String> highlights;   // Highlighted verses
  
  // AI Integration
  final int questionsAsked;        // AI questions during reading
  final List<String> topicsExplored; // AI chat topics
}

enum ReadingMethod {
  sequential,      // Reading Bible in order
  topical,         // Studying specific topics
  planBased,       // Following reading plan
  random,          // Jumping around
}
```

### **2. Reading Plans & Goals**
```dart
class BibleReadingPlan {
  final String id;
  final String name;               // "One Year Bible", "90 Day NT"
  final String description;
  final int totalDays;
  final List<DailyReading> schedule;
  final PlanDifficulty difficulty;
  final List<String> focusAreas;   // OT, NT, Psalms, etc.
  
  // Progress tracking
  final int currentDay;
  final double completionPercentage;
  final int streakDays;
  final DateTime? lastReadDate;
  final bool isActive;
}

class DailyReading {
  final int day;
  final List<BibleReference> readings; // Multiple passages per day
  final String? theme;             // Daily theme or focus
  final String? reflection;        // Reflection questions
  final bool completed;
  final DateTime? completedAt;
}

class BibleReference {
  final String book;
  final int startChapter;
  final int? endChapter;           // For multi-chapter readings
  final int? startVerse;           // For partial chapters
  final int? endVerse;
}

enum PlanDifficulty { beginner, intermediate, advanced }
```

### **3. Reading Statistics & Analytics**
```dart
class ReadingStatistics {
  // Daily stats
  final int dailyStreak;           // Current reading streak
  final int longestStreak;         // Best streak ever
  final Duration todayReadingTime;
  final int todayChapters;
  
  // Weekly/Monthly stats
  final Duration weeklyReadingTime;
  final int weeklyChapters;
  final Duration monthlyReadingTime;
  final int monthlyChapters;
  
  // All-time stats
  final int totalChaptersRead;
  final int totalBooksCompleted;
  final Duration totalReadingTime;
  final DateTime firstReadingDate;
  final int daysActive;
  
  // Reading habits
  final TimeOfDay preferredReadingTime;
  final Duration averageSessionLength;
  final List<String> favoriteBooks;
  final Map<String, int> bookCompletionCount; // How many times read each book
  
  // AI interaction stats
  final int totalQuestionsAsked;
  final List<String> topTopicsExplored;
  final int studyNotesCreated;
}
```

---

## 🎨 **User Interface Design**

### **1. Reading Dashboard**
```dart
class BibleReadingDashboard extends StatefulWidget {
  @override
  State<BibleReadingDashboard> createState() => _BibleReadingDashboardState();
}

class _BibleReadingDashboardState extends State<BibleReadingDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bible Reading Journey'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.analytics),
            onPressed: () => _showDetailedAnalytics(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Current streak card
            _buildStreakCard(),
            SizedBox(height: 16),
            
            // Today's reading progress
            _buildTodayProgressCard(),
            SizedBox(height: 16),
            
            // Active reading plan
            _buildReadingPlanCard(),
            SizedBox(height: 16),
            
            // Quick stats grid
            _buildQuickStatsGrid(),
            SizedBox(height: 16),
            
            // Recent reading history
            _buildRecentReadingHistory(),
            SizedBox(height: 16),
            
            // Achievements section
            _buildAchievementsSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startReading,
        icon: Icon(Icons.book),
        label: Text('Start Reading'),
        backgroundColor: Colors.brown,
      ),
    );
  }
  
  Widget _buildStreakCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_fire_department, 
                   color: Colors.white, size: 32),
              SizedBox(width: 8),
              Text(
                'Reading Streak',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '${_currentStreak}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _currentStreak == 1 ? 'day' : 'days',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Best: ${_longestStreak} days',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTodayProgressCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Today\'s Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Reading time progress
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reading Time'),
                      SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: _todayReadingMinutes / _dailyGoalMinutes,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation(Colors.green),
                      ),
                      SizedBox(height: 4),
                      Text('${_todayReadingMinutes}/${_dailyGoalMinutes} min'),
                    ],
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Chapters Read'),
                      SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: _todayChapters / _dailyChapterGoal,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation(Colors.blue),
                      ),
                      SizedBox(height: 4),
                      Text('${_todayChapters}/${_dailyChapterGoal}'),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Today's planned reading
            if (_todayPlannedReading.isNotEmpty) ...[
              Text(
                'Today\'s Plan:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              ...(_todayPlannedReading.map((reading) => 
                _buildPlannedReadingItem(reading)
              )),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildReadingPlanCard() {
    if (_activeReadingPlan == null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.route, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'No Active Reading Plan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Choose a reading plan to track your progress',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _choosePlan,
                child: Text('Choose Plan'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route, color: Colors.purple),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _activeReadingPlan!.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _viewPlanDetails,
                  child: Text('Details'),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            // Plan progress
            LinearProgressIndicator(
              value: _activeReadingPlan!.completionPercentage / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(Colors.purple),
            ),
            SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Day ${_activeReadingPlan!.currentDay} of ${_activeReadingPlan!.totalDays}',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${_activeReadingPlan!.completionPercentage.toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          'Total Chapters',
          '${_totalChaptersRead}',
          Icons.book,
          Colors.blue,
        ),
        _buildStatCard(
          'Books Completed',
          '${_booksCompleted}',
          Icons.library_books,
          Colors.green,
        ),
        _buildStatCard(
          'Reading Time',
          _formatDuration(_totalReadingTime),
          Icons.schedule,
          Colors.orange,
        ),
        _buildStatCard(
          'AI Questions',
          '${_totalAIQuestions}',
          Icons.psychology,
          Colors.purple,
        ),
      ],
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
```

### **2. Reading Session Tracker**
```dart
class BibleReadingSession extends StatefulWidget {
  final BibleChapter chapter;
  final BibleReadingPlan? activePlan;
  
  @override
  State<BibleReadingSession> createState() => _BibleReadingSessionState();
}

class _BibleReadingSessionState extends State<BibleReadingSession> {
  late Stopwatch _stopwatch;
  Timer? _timer;
  int _currentVerse = 1;
  Set<int> _readVerses = {};
  List<String> _highlights = [];
  String _sessionNotes = '';
  int _aiQuestionsAsked = 0;
  
  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    _startSession();
  }
  
  void _startSession() {
    _stopwatch.start();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
    
    // Track session start
    _trackSessionStart();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.chapter.book} ${widget.chapter.chapter}'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          // Reading timer
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer, size: 16),
                SizedBox(width: 4),
                Text(_formatStopwatchTime(_stopwatch.elapsed)),
              ],
            ),
          ),
          
          // Notes button
          IconButton(
            icon: Icon(Icons.note_add),
            onPressed: _showNotesDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildReadingProgress(),
          
          // Bible text with verse tracking
          Expanded(
            child: _buildBibleTextWithTracking(),
          ),
          
          // Session controls
          _buildSessionControls(),
        ],
      ),
    );
  }
  
  Widget _buildReadingProgress() {
    final progress = _readVerses.length / widget.chapter.verses.length;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.brown.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reading Progress',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation(Colors.brown),
                    ),
                    SizedBox(height: 4),
                    Text('${_readVerses.length}/${widget.chapter.verses.length} verses'),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Column(
                children: [
                  Icon(Icons.timer, color: Colors.brown),
                  Text(_formatStopwatchTime(_stopwatch.elapsed)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildBibleTextWithTracking() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: widget.chapter.verses.length,
      itemBuilder: (context, index) {
        final verse = widget.chapter.verses[index];
        final isRead = _readVerses.contains(verse.number);
        final isHighlighted = _highlights.contains('${widget.chapter.book} ${widget.chapter.chapter}:${verse.number}');
        
        return GestureDetector(
          onTap: () => _markVerseAsRead(verse.number),
          onLongPress: () => _showVerseOptions(verse),
          child: Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isRead 
                ? Colors.green.withOpacity(0.1)
                : isHighlighted 
                  ? Colors.yellow.withOpacity(0.3)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isRead 
                  ? Colors.green.withOpacity(0.3)
                  : Colors.transparent,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Verse number
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isRead ? Colors.green : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${verse.number}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isRead ? Colors.white : Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                
                // Verse text
                Expanded(
                  child: Text(
                    verse.text,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: isRead ? Colors.black87 : Colors.black54,
                    ),
                  ),
                ),
                
                // Read indicator
                if (isRead) 
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildSessionControls() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // AI Chat button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _openAIChat,
              icon: Icon(Icons.psychology),
              label: Text('Ask AI'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 12),
          
          // Complete session button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _completeSession,
              icon: Icon(Icons.check),
              label: Text('Complete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _markVerseAsRead(int verseNumber) {
    setState(() {
      if (_readVerses.contains(verseNumber)) {
        _readVerses.remove(verseNumber);
      } else {
        _readVerses.add(verseNumber);
      }
    });
    
    // Track reading progress
    _trackVerseRead(verseNumber);
  }
  
  void _showVerseOptions(BibleVerse verse) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.chapter.book} ${widget.chapter.chapter}:${verse.number}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            ListTile(
              leading: Icon(Icons.highlight),
              title: Text('Highlight Verse'),
              onTap: () {
                _highlightVerse(verse);
                Navigator.pop(context);
              },
            ),
            
            ListTile(
              leading: Icon(Icons.psychology),
              title: Text('Ask AI About This Verse'),
              onTap: () {
                Navigator.pop(context);
                _askAIAboutVerse(verse);
              },
            ),
            
            ListTile(
              leading: Icon(Icons.note_add),
              title: Text('Add Note'),
              onTap: () {
                Navigator.pop(context);
                _addVerseNote(verse);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _completeSession() async {
    _stopwatch.stop();
    _timer?.cancel();
    
    // Calculate session statistics
    final sessionStats = BibleReadingSession(
      userId: FirebaseAuth.instance.currentUser!.uid,
      date: DateTime.now(),
      bookName: widget.chapter.book,
      chapter: widget.chapter.chapter,
      versesRead: _readVerses.toList(),
      readingTime: _stopwatch.elapsed,
      wordsRead: _calculateWordsRead(),
      completedChapter: _readVerses.length == widget.chapter.verses.length,
      method: widget.activePlan != null ? ReadingMethod.planBased : ReadingMethod.sequential,
      notes: _sessionNotes,
      highlights: _highlights,
      questionsAsked: _aiQuestionsAsked,
      topicsExplored: [], // Will be populated by AI service
    );
    
    // Save session to database
    await _saveReadingSession(sessionStats);
    
    // Show completion dialog
    await _showSessionComplete(sessionStats);
    
    // Navigate back
    Navigator.pop(context);
  }
}
```

---

## 🏆 **Achievement System**

### **Reading Achievements**
```dart
class BibleReadingAchievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final AchievementType type;
  final Map<String, dynamic> criteria;
  final int points;
  final DateTime? unlockedAt;
  final bool isUnlocked;
}

enum AchievementType {
  streak,          // Reading streaks
  completion,      // Completing books/chapters
  time,           // Reading time milestones
  consistency,    // Regular reading habits
  exploration,    // Reading different books
  study,          // AI questions and notes
  special,        // Special occasions
}

class AchievementDefinitions {
  static final List<BibleReadingAchievement> achievements = [
    // Streak achievements
    BibleReadingAchievement(
      id: 'first_day',
      title: 'First Steps',
      description: 'Complete your first day of Bible reading',
      icon: Icons.looks_one,
      color: Colors.green,
      type: AchievementType.streak,
      criteria: {'streak_days': 1},
      points: 10,
    ),
    
    BibleReadingAchievement(
      id: 'week_warrior',
      title: 'Week Warrior',
      description: 'Read for 7 consecutive days',
      icon: Icons.calendar_view_week,
      color: Colors.blue,
      type: AchievementType.streak,
      criteria: {'streak_days': 7},
      points: 50,
    ),
    
    BibleReadingAchievement(
      id: 'month_master',
      title: 'Month Master',
      description: 'Read for 30 consecutive days',
      icon: Icons.calendar_month,
      color: Colors.purple,
      type: AchievementType.streak,
      criteria: {'streak_days': 30},
      points: 200,
    ),
    
    // Completion achievements
    BibleReadingAchievement(
      id: 'genesis_complete',
      title: 'In the Beginning',
      description: 'Complete the book of Genesis',
      icon: Icons.auto_stories,
      color: Colors.brown,
      type: AchievementType.completion,
      criteria: {'book': 'Kejadian', 'completion': 100},
      points: 100,
    ),
    
    BibleReadingAchievement(
      id: 'psalm_lover',
      title: 'Psalm Lover',
      description: 'Read 50 chapters from Psalms',
      icon: Icons.music_note,
      color: Colors.amber,
      type: AchievementType.completion,
      criteria: {'book': 'Mazmur', 'chapters': 50},
      points: 150,
    ),
    
    BibleReadingAchievement(
      id: 'new_testament',
      title: 'New Covenant',
      description: 'Complete the entire New Testament',
      icon: Icons.new_releases,
      color: Colors.indigo,
      type: AchievementType.completion,
      criteria: {'testament': 'new', 'completion': 100},
      points: 500,
    ),
    
    // Time achievements
    BibleReadingAchievement(
      id: 'hour_student',
      title: 'Dedicated Student',
      description: 'Spend 1 hour reading in a single session',
      icon: Icons.schedule,
      color: Colors.orange,
      type: AchievementType.time,
      criteria: {'session_minutes': 60},
      points: 75,
    ),
    
    BibleReadingAchievement(
      id: 'marathon_reader',
      title: 'Marathon Reader',
      description: 'Accumulate 100 hours of total reading time',
      icon: Icons.timer,
      color: Colors.red,
      type: AchievementType.time,
      criteria: {'total_hours': 100},
      points: 300,
    ),
    
    // Study achievements
    BibleReadingAchievement(
      id: 'curious_mind',
      title: 'Curious Mind',
      description: 'Ask 100 questions to the AI Bible assistant',
      icon: Icons.psychology,
      color: Colors.purple,
      type: AchievementType.study,
      criteria: {'ai_questions': 100},
      points: 150,
    ),
    
    BibleReadingAchievement(
      id: 'note_taker',
      title: 'Faithful Scribe',
      description: 'Create 50 personal study notes',
      icon: Icons.edit_note,
      color: Colors.teal,
      type: AchievementType.study,
      criteria: {'notes_created': 50},
      points: 100,
    ),
    
    // Special achievements
    BibleReadingAchievement(
      id: 'christmas_reader',
      title: 'Christmas Story',
      description: 'Read the Christmas story during December',
      icon: Icons.celebration,
      color: Colors.red,
      type: AchievementType.special,
      criteria: {'verses': ['Luke 2:1-20', 'Matthew 1:18-25'], 'month': 12},
      points: 50,
    ),
    
    BibleReadingAchievement(
      id: 'easter_reader',
      title: 'Resurrection Hope',
      description: 'Read the Easter story during Holy Week',
      icon: Icons.favorite,
      color: Colors.pink,
      type: AchievementType.special,
      criteria: {'verses': ['Matthew 28', 'Mark 16', 'Luke 24', 'John 20']},
      points: 75,
    ),
  ];
}
```

---

## 📊 **Reading Analytics Dashboard**

### **Detailed Analytics Page**
```dart
class BibleAnalyticsPage extends StatefulWidget {
  @override
  State<BibleAnalyticsPage> createState() => _BibleAnalyticsPageState();
}

class _BibleAnalyticsPageState extends State<BibleAnalyticsPage> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reading Analytics'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Progress'),
            Tab(text: 'Habits'),
            Tab(text: 'Goals'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildProgressTab(),
          _buildHabitsTab(),
          _buildGoalsTab(),
        ],
      ),
    );
  }
  
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Reading streak chart
          _buildStreakChart(),
          SizedBox(height: 20),
          
          // Monthly reading time
          _buildMonthlyTimeChart(),
          SizedBox(height: 20),
          
          // Book completion progress
          _buildBookCompletionChart(),
          SizedBox(height: 20),
          
          // Recent achievements
          _buildRecentAchievements(),
        ],
      ),
    );
  }
  
  Widget _buildStreakChart() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reading Streak History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            // Streak visualization (last 30 days)
            Container(
              height: 100,
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: 30,
                itemBuilder: (context, index) {
                  final date = DateTime.now().subtract(Duration(days: 29 - index));
                  final hasReading = _hasReadingOnDate(date);
                  
                  return Container(
                    decoration: BoxDecoration(
                      color: hasReading ? Colors.green : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 10,
                          color: hasReading ? Colors.white : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: 8),
                Text('Reading day', style: TextStyle(fontSize: 12)),
                SizedBox(width: 16),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: 8),
                Text('No reading', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProgressTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Bible completion progress
          _buildBibleProgressOverview(),
          SizedBox(height: 20),
          
          // Book-by-book progress
          _buildBookProgressList(),
        ],
      ),
    );
  }
  
  Widget _buildBibleProgressOverview() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Bible Reading Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            
            // Old Testament progress
            _buildTestamentProgress(
              'Old Testament',
              _oldTestamentProgress,
              Colors.brown,
            ),
            SizedBox(height: 16),
            
            // New Testament progress
            _buildTestamentProgress(
              'New Testament',
              _newTestamentProgress,
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTestamentProgress(String title, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ],
    );
  }
}
```

---

## 💰 **Premium Integration**

### **Free vs Premium Features**

#### **Free Users**
- ✅ Basic reading tracking (chapters completed)
- ✅ Simple streak counter (max 7 days visible)
- ✅ Basic achievements (first 5 achievements only)
- ❌ Detailed analytics and charts
- ❌ Reading plans
- ❌ Session notes and highlights
- ❌ AI integration tracking

#### **Premium Users**
- ✅ **Complete Reading Analytics** - Detailed charts and statistics
- ✅ **Reading Plans** - Structured Bible reading schedules
- ✅ **Session Tracking** - Detailed reading sessions with time tracking
- ✅ **Notes & Highlights** - Personal study annotations
- ✅ **AI Integration** - Track AI questions and study insights
- ✅ **Full Achievement System** - All 50+ achievements
- ✅ **Export Data** - Download reading history and analytics
- ✅ **Goal Setting** - Custom reading goals and targets

---

## 🚀 **Implementation Benefits**

### **User Engagement**
1. **Daily Habit Formation** - Streak tracking encourages daily reading
2. **Gamification** - Achievements make Bible study fun and rewarding
3. **Progress Visualization** - Charts show reading journey progress
4. **Goal Achievement** - Clear targets motivate consistent reading

### **Premium Value**
1. **Essential Tool** - Serious Bible students need progress tracking
2. **Data Insights** - Analytics provide valuable reading insights
3. **Study Enhancement** - Notes and highlights improve retention
4. **AI Integration** - Links with AI chat for comprehensive study

### **Technical Integration**
1. **Bible Feature Synergy** - Works seamlessly with Bible reading
2. **AI Chat Enhancement** - Tracks study questions and insights
3. **Existing Infrastructure** - Uses current Firebase and premium systems
4. **Performance Optimized** - Efficient data storage and retrieval

## ✨ **This Completes the Bible Study Ecosystem!**

**Bible Reading + AI Chat + Progress Tracking = Complete Premium Experience**

The combination of these three features would create an unbeatable premium offering:
- **📖 Bible Reading** - Access to complete Malay/Indonesian Bible
- **🤖 AI Chat** - Intelligent study companion for deeper understanding  
- **📊 Reading Tracking** - Comprehensive progress analytics and gamification

**Users would get a complete digital discipleship tool that tracks their spiritual growth journey while providing intelligent guidance - worth every ringgit of the RM 15.00 subscription!**

**Ready to implement the reading tracking system? I can start with the core tracking models and dashboard!** 📊📖🎯
