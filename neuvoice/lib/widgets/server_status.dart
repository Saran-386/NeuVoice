import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../utils/responsive_utils.dart';
import '../utils/constants.dart';

class ServerStatus extends StatelessWidget {
  const ServerStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiService>(
      builder: (context, apiService, child) {
        return Container(
          padding: EdgeInsets.all(ResponsiveUtils.getPadding(context) * 0.75),
          decoration: BoxDecoration(
            color: _getStatusColor(apiService.isConnected).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getStatusColor(apiService.isConnected),
              width: 1,
            ),
          ),
          child: IntrinsicHeight(
            // Fixed: Proper height calculation
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Fixed: Proper alignment
              children: [
                // Status indicator - Fixed with SizedBox for consistent sizing
                SizedBox(
                  width: ResponsiveUtils.isPhone(context) ? 16 : 18,
                  height: ResponsiveUtils.isPhone(context) ? 16 : 18,
                  child: apiService.isLoading
                      ? CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                              _getStatusColor(apiService.isConnected)),
                        )
                      : Icon(
                          _getStatusIcon(apiService.isConnected),
                          color: _getStatusColor(apiService.isConnected),
                          size: ResponsiveUtils.isPhone(context) ? 16 : 18,
                        ),
                ),
                const SizedBox(width: 8),

                // Text content - Fixed with proper constraints
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment:
                        MainAxisAlignment.center, // Fixed: Center alignment
                    children: [
                      Text(
                        _getStatusTitle(
                            apiService.isConnected, apiService.isLoading),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(apiService.isConnected),
                          fontSize:
                              ResponsiveUtils.getFontSize(context, base: 12),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1, // Fixed: Explicit max lines
                      ),
                      const SizedBox(height: 2), // Fixed: Small spacing
                      Text(
                        _getStatusSubtitle(
                            apiService.isConnected, apiService.isLoading),
                        style: TextStyle(
                          color: _getStatusColor(apiService.isConnected)
                              .withOpacity(0.8),
                          fontSize:
                              ResponsiveUtils.getFontSize(context, base: 10),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),

                // Refresh button - Fixed with consistent sizing
                if (!apiService.isLoading) ...[
                  SizedBox(
                    width: ResponsiveUtils.isPhone(context) ? 40 : 44,
                    height: ResponsiveUtils.isPhone(context) ? 40 : 44,
                    child: IconButton(
                      onPressed: apiService.recheckConnection,
                      icon: Icon(
                        Icons.refresh,
                        size: ResponsiveUtils.isPhone(context) ? 18 : 20,
                        color: _getStatusColor(apiService.isConnected),
                      ),
                      tooltip: 'Refresh connection',
                      padding: EdgeInsets.zero, // Fixed: Remove extra padding
                      constraints:
                          const BoxConstraints(), // Fixed: Remove default constraints
                    ),
                  ),
                ] else ...[
                  // Fixed: Placeholder when loading to maintain layout consistency
                  SizedBox(
                    width: ResponsiveUtils.isPhone(context) ? 40 : 44,
                    height: ResponsiveUtils.isPhone(context) ? 40 : 44,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getStatusIcon(bool isConnected) =>
      isConnected ? Icons.cloud_done : Icons.cloud_off;

  Color _getStatusColor(bool isConnected) => isConnected
      ? const Color(AppConstants.successColor)
      : const Color(AppConstants.errorColor);

  String _getStatusTitle(bool isConnected, bool isLoading) {
    if (isLoading) return 'Checking connection...';
    return isConnected ? 'Pi Connected' : 'Pi Disconnected';
  }

  String _getStatusSubtitle(bool isConnected, bool isLoading) {
    if (isLoading) return 'Please wait...';
    if (isConnected) {
      return 'Ready to transcribe • ${AppConstants.piServerUrl}';
    }
    return 'Check Pi server • ${AppConstants.piServerUrl}';
  }
}
