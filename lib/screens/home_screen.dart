import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/mqtt_service.dart';
import '../widgets/status_indicator.dart';
import '../widgets/chart_widget.dart';
import '../widgets/fan_control_card.dart';
import '../widgets/mini_stat_card.dart';
import '../models/sensor_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final MqttService _mqttService = MqttService();
  bool _isConnected = false;
  late TabController _tabController;

  final List<SensorData> _gasData = [];
  final List<SensorData> _tempData = [];
  final int _maxDataPoints = 20;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _connectToMqtt();
  }

  Future<void> _connectToMqtt() async {
    await _mqttService.connect();

    _mqttService.connectionStream.listen((connected) {
      setState(() {
        _isConnected = connected;
      });
    });

    _mqttService.gasStream.listen((value) {
      setState(() {
        _gasData.add(SensorData(timestamp: DateTime.now(), value: value));
        if (_gasData.length > _maxDataPoints) {
          _gasData.removeAt(0);
        }
      });
    });

    _mqttService.tempStream.listen((value) {
      setState(() {
        _tempData.add(SensorData(timestamp: DateTime.now(), value: value));
        if (_tempData.length > _maxDataPoints) {
          _tempData.removeAt(0);
        }
      });
    });

    _mqttService.alertStream.listen((status) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _mqttService.disconnect();
    _mqttService.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF2196F3),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'SentiGas Monitor',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16, top: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isConnected
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isConnected ? 'Online' : 'Offline',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: RefreshIndicator(
              onRefresh: () async {
                await _connectToMqtt();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Alert
                    StatusIndicator(status: _mqttService.currentStatus),
                    const SizedBox(height: 20),

                    // Mini Stats Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        MiniStatCard(
                          title: 'Gas LPG',
                          value: _mqttService.currentGas.toStringAsFixed(1),
                          unit: 'PPM',
                          icon: Icons.cloud_outlined,
                          color: _getGasColor(_mqttService.currentGas),
                        ),
                        MiniStatCard(
                          title: 'Temperature',
                          value: _mqttService.currentTemp.toStringAsFixed(1),
                          unit: '°C',
                          icon: Icons.thermostat_outlined,
                          color: _getTempColor(_mqttService.currentTemp),
                        ),
                        MiniStatCard(
                          title: 'Humidity',
                          value: _mqttService.currentHumidity.toStringAsFixed(
                            1,
                          ),
                          unit: '%',
                          icon: Icons.water_drop_outlined,
                          color: const Color(0xFF3498DB),
                        ),
                        MiniStatCard(
                          title: 'Fan Speed',
                          value:
                              '${(_mqttService.currentFanSpeed / 255 * 100).toInt()}',
                          unit: '%',
                          icon: Icons.air,
                          color: const Color(0xFF9B59B6),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Fan Control Card
                    FanControlCard(
                      fanSpeed: _mqttService.currentFanSpeed,
                      isManual: _mqttService.manualMode,
                      onSpeedChanged: (speed) {
                        _mqttService.setFanSpeed(speed);
                      },
                      onModeChanged: (manual) {
                        setState(() {
                          _mqttService.setManualMode(manual);
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Tab Bar for Charts
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TabBar(
                            controller: _tabController,
                            labelColor: const Color(0xFF2196F3),
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: const Color(0xFF2196F3),
                            indicatorWeight: 3,
                            labelStyle: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            tabs: const [
                              Tab(icon: Icon(Icons.cloud), text: 'Gas LPG'),
                              Tab(
                                icon: Icon(Icons.thermostat),
                                text: 'Temperature',
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 280,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: ChartWidget(
                                    title: 'Gas LPG Trend',
                                    data: _gasData,
                                    color: _getGasColor(
                                      _mqttService.currentGas,
                                    ),
                                    maxY: 1000,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: ChartWidget(
                                    title: 'Temperature Trend',
                                    data: _tempData,
                                    color: _getTempColor(
                                      _mqttService.currentTemp,
                                    ),
                                    maxY: 50,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Info Section - Modern Design
                    _buildModernInfoSection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF34495E), Color(0xFF2C3E50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'System Information',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildModernInfoRow(
            Icons.router,
            'MQTT Broker',
            'broker.emqx.io:1883',
          ),
          const Divider(color: Colors.white24, height: 24),
          _buildModernInfoRow(Icons.topic, 'Topics', '6 channels subscribed'),
          const Divider(color: Colors.white24, height: 24),
          _buildModernInfoRow(Icons.speed, 'Update Rate', 'Every 2 seconds'),
          const Divider(color: Colors.white24, height: 24),
          _buildModernInfoRow(
            Icons.storage,
            'Data Points',
            '20 samples buffered',
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getGasColor(double gas) {
    if (gas > 500) return const Color(0xFFE74C3C);
    if (gas > 200) return const Color(0xFFF39C12);
    return const Color(0xFF27AE60);
  }

  Color _getTempColor(double temp) {
    if (temp > 35) return const Color(0xFFE74C3C);
    if (temp > 30) return const Color(0xFFF39C12);
    return const Color(0xFF3498DB);
  }
}
