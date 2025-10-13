
import SwiftUI

struct HighlightSettingsView: View {
    @Binding var highlightRules: [String: Double]
    let modelLabels: [String]
    
    @State private var newLabel: String = ""
    @State private var newConfidence: Double = 0.8
    @FocusState private var isLabelFieldFocused: Bool
    
    private var sortedRules: [(key: String, value: Double)] {
        highlightRules.sorted { $0.key < $1.key }
    }
    
    private var filteredLabels: [String] {
        if newLabel.isEmpty {
            return []
        }
        return modelLabels.filter { $0.lowercased().contains(newLabel.lowercased()) }
    }
    
    private var isNewLabelValid: Bool {
        !newLabel.isEmpty && modelLabels.contains(newLabel.lowercased())
    }
    
    private var canAddRule: Bool {
        isNewLabelValid && highlightRules[newLabel.lowercased()] == nil
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: Color.appMixedGradient2, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    headerView
                    currentRulesSection
                    newRuleSection
                    Spacer()
                }
            }
        }
        .navigationTitle("Highlight Rules")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var headerView: some View {
        VStack {
            Text("Highlight Rules")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Text("Objects to highlight in the live camera")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.top, 20)
    }
    
    @ViewBuilder
    private var currentRulesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Rules")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
            
            if highlightRules.isEmpty {
                emptyRulesView
            } else {
                rulesListView
            }
        }
    }
    
    private var emptyRulesView: some View {
        Text("No highlight rules set. Add one below.")
            .font(.system(size: 15))
            .foregroundStyle(.white.opacity(0.6))
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)
    }
    
    private var rulesListView: some View {
        VStack(spacing: 12) {
            ForEach(sortedRules, id: \.key) { key, value in
                HighlightRuleRow(
                    label: key, 
                    confidence: value,
                    onSelect: {
                        selectRuleForEditing(label: key, confidence: value)
                    },
                    onDelete: {
                        withAnimation {
                            highlightRules[key] = nil
                        }
                    }
                )
            }
        }
        .padding(.horizontal, 24)
    }
    
    private var newRuleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add New Rule")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
            
            VStack(spacing: 16) {
                autocompleteTextField
                confidenceSlider
                addRuleButton
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 24)
        }
    }
    
    @ViewBuilder
    private var autocompleteTextField: some View {
        VStack {
            HStack {
                TextField("Object Label (e.g., 'cup')", text: $newLabel)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($isLabelFieldFocused)
                
                if isNewLabelValid {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
            }
            
            if isLabelFieldFocused && !filteredLabels.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(filteredLabels.prefix(10), id: \.self) { label in
                            Button(action: {
                                self.newLabel = label
                                self.isLabelFieldFocused = false
                            }) {
                                Text(label)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.appAccent.opacity(0.8))
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            } else {
                EmptyView()
            }
        }
    }
    
    private var confidenceSlider: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Confidence")
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Text("\(Int(newConfidence * 100))%")
                    .foregroundStyle(.white)
                    .fontWeight(.semibold)
            }
            Slider(value: $newConfidence, in: 0.3...1.0)
                .tint(.appAccent)
        }
    }
    
    private var addRuleButton: some View {
        Button(action: addRule) {
            Text(canAddRule ? "Add Rule" : buttonText)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canAddRule ? Color.appAccent : Color.gray.opacity(0.5))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!canAddRule)
    }
    
    private var buttonText: String {
        if newLabel.isEmpty {
            return "Enter a label"
        } else if !isNewLabelValid {
            return "Invalid Label"
        } else {
            return "Rule Already Exists"
        }
    }
    
    private func addRule() {
        guard canAddRule else { return }
        let key = newLabel.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        highlightRules[key] = newConfidence
        newLabel = ""
        newConfidence = 0.8
        isLabelFieldFocused = false
    }
    
    private func selectRuleForEditing(label: String, confidence: Double) {
        // Immediately remove the rule to allow it to be re-added
        highlightRules.removeValue(forKey: label)
        
        // Populate the form for editing
        newLabel = label
        newConfidence = confidence
        isLabelFieldFocused = true
    }
}

// MARK: - Highlight Rule Row
struct HighlightRuleRow: View {
    let label: String
    let confidence: Double
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.appAccent)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(label.capitalized)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Text("Confidence > \(Int(confidence * 100))%")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.red)
                        .padding(8)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    // 1. Create a simple container View to hold the state.
    //    This is a common and recommended pattern for previews.
    struct HighlightSettingsPreviewWrapper: View {
        // 2. The @State variable now lives inside a proper View struct.
        @State var rules: [String: Double] = ["cat": 0.8, "dog": 0.7]
        let labels = ["cat", "dog", "bird", "car", "bicycle", "boat"]
        
        var body: some View {
            NavigationStack {
                HighlightSettingsView(highlightRules: $rules, modelLabels: labels)
            }
        }
    }
    
    // 3. Return an instance of the new wrapper view.
    return HighlightSettingsPreviewWrapper()
}
