# Cost Tracking Feature Implementation

## Overview
This feature allows users to see how much each meeting has cost in terms of OpenAI API usage. The implementation tracks both transcription and notes generation costs based on the provided model pricing.

## Pricing Structure
The implementation uses the following pricing:

### gpt-4o-mini-transcribe model
- $1.25/million tokens input
- $5.00/million tokens output
- $0.003/minute expected cost

### gpt-4.1 model
- $2.00/million tokens input
- $0.50/million tokens cached input
- $8.00/million tokens output

## Implementation Details

### New Files Created
- **`/workspace/notetaker/Services/CostCalculator.swift`** - Core cost calculation logic

### Modified Files
- **`/workspace/notetaker/Models/Meeting.swift`** - Added cost tracking fields and computed properties
- **`/workspace/notetaker/Services/NotesGenerator.swift`** - Updated to capture actual API usage
- **`/workspace/notetaker/ViewModels/MeetingViewModel.swift`** - Updated to handle cost tracking
- **`/workspace/notetaker/Views/MeetingDetailView.swift`** - Added cost display in meeting details
- **`/workspace/notetaker/Views/MeetingListView.swift`** - Added cost display in meeting list

### Key Features

#### 1. Cost Calculation
- **Estimated costs** - Uses token count estimation for quick cost preview
- **Actual costs** - Tracks real API usage when available
- **Separate tracking** - Distinguishes between transcription and notes generation costs

#### 2. Cost Display
- **Meeting List** - Shows total cost for each meeting in the list
- **Meeting Details** - Displays cost with detailed breakdown on tap
- **Real-time Updates** - Cost updates as meetings are processed

#### 3. Data Structure
- **`MeetingCostInfo`** - Stores detailed token usage and cost information
- **`ModelPricing`** - Configurable pricing structure for different models
- **Version Migration** - Updated data version from 1 to 2 for backward compatibility

## Usage Instructions

### For Users
1. **View Costs** - Costs are automatically displayed in both meeting list and detail views
2. **Detailed Breakdown** - Tap on the cost in meeting details to see breakdown
3. **Estimation vs Actual** - The system shows estimated costs until actual API usage is available

### For Developers
1. **Cost Calculation** - Use `CostCalculator.shared.estimateTotalCost(for: meeting)` for estimates
2. **Actual Usage** - API responses automatically populate actual usage data
3. **Pricing Updates** - Modify pricing constants in `CostCalculator.swift`

## Technical Notes

### Token Estimation
- Uses approximate conversion: 1 token ≈ 4 characters
- More accurate tokenization could be implemented using OpenAI's tiktoken library

### Cost Tracking
- Transcription costs are estimated based on meeting duration ($0.003/minute)
- Notes generation costs are calculated from actual API responses
- Cached input tokens are tracked separately for gpt-4.1 pricing

### UI Implementation
- Cost display is non-intrusive and blends with existing design
- Breakdown dialog provides detailed cost information
- Costs are formatted to 3 decimal places for precision

## Future Enhancements

1. **Total Cost Summary** - Add overall cost tracking across all meetings
2. **Cost Alerts** - Notify users when costs exceed certain thresholds
3. **Export Functionality** - Allow users to export cost reports
4. **Budget Tracking** - Set monthly/weekly budget limits
5. **More Accurate Tokenization** - Integrate OpenAI's tiktoken for precise token counting

## Testing

The implementation includes:
- Proper error handling for missing API responses
- Fallback to estimated costs when actual data is unavailable
- Backward compatibility with existing meeting data
- UI responsiveness for cost updates

## Pricing Model Updates

To update pricing for different models:
1. Modify the pricing constants in `CostCalculator.swift`
2. Update the pricing structure in `ModelPricing` if needed
3. Ensure proper cost calculation methods are used for each model type