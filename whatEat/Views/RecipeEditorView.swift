import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

private extension UTType {
    static let recipeEditorItem = UTType(exportedAs: "com.whateat.recipe-editor-item")
}

struct RecipeEditorView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @Environment(SavedRecipesStore.self) private var savedRecipesStore
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: RecipeEditorViewModel
    @State private var showPhotoSourceSheet = false
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var showTimePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var pendingCameraImage: UIImage?
    @State private var draggingIngredient: RecipeEditorItem?
    @State private var draggingInstruction: RecipeEditorItem?
    @FocusState private var focusedField: FocusField?

    private let coralColor = Color(red: 0.96, green: 0.58, blue: 0.53)
    private let softGreen = Color(red: 0.56, green: 0.82, blue: 0.67)

    private enum FocusField: Hashable {
        case name
        case calories
        case ingredient(UUID)
        case instruction(UUID)
    }

    init(mode: RecipeEditorViewModel.Mode) {
        _viewModel = State(initialValue: RecipeEditorViewModel(mode: mode))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                coverPhotoSection
                nameSection
                ingredientsSection
                instructionsSection
                detailsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .contentShape(Rectangle())
        .gesture(TapGesture().onEnded {
            dismissInputs()
        }, including: .gesture)
        .background(Color(.systemBackground))
        .navigationTitle(viewModel.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                let canSave = viewModel.hasRequiredFields
                    && !viewModel.isSaving
                    && !viewModel.isUploadingCoverPhoto
                    && viewModel.isCoverPhotoReadyForSave
                Button {
                    dismissInputs()
                    Task {
                        await handleSave()
                    }
                } label: {
                    if viewModel.isSaving {
                        ProgressView()
                            .tint(coralColor)
                    } else {
                        Text("Save")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .disabled(!canSave)
                .foregroundColor(canSave ? coralColor : .secondary)
            }
        }
        .confirmationDialog("Cover Photo", isPresented: $showPhotoSourceSheet) {
            Button("Take Photo") {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    showCamera = true
                } else {
                    viewModel.errorMessage = "Camera not available on this device."
                }
            }
            Button("Upload from Camera Roll") {
                showPhotoLibrary = true
            }
            if viewModel.coverPhotoImage != nil || viewModel.coverPhotoURL != nil {
                Button("Remove Photo", role: .destructive) {
                    viewModel.removeCoverPhoto()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose a cover photo for your recipe.")
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker(image: $pendingCameraImage)
                .ignoresSafeArea()
        }
        .photosPicker(isPresented: $showPhotoLibrary, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: pendingCameraImage) { _, newImage in
            guard let newImage else { return }
            startCoverPhotoUpload(for: newImage)
            pendingCameraImage = nil
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    startCoverPhotoUpload(for: image)
                }
            }
        }
        .onChange(of: viewModel.caloriesText) { _, newValue in
            let filtered = newValue.filter { $0.isNumber }
            if filtered != newValue {
                viewModel.caloriesText = filtered
            }
        }
        .onChange(of: showTimePicker) { _, newValue in
            if !newValue {
                NotificationCenter.default.post(name: .shakeDetectorRestore, object: nil)
            }
        }
        .sheet(isPresented: $showTimePicker) {
            TimePickerSheet(hours: modelBinding(\.prepHours), minutes: modelBinding(\.prepMinutes))
                .presentationDetents([.medium])
        }
        .alert(
            "Unable to save",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.errorMessage = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "Something went wrong.")
        }
    }

    private var coverPhotoSection: some View {
        Button {
            dismissInputs()
            showPhotoSourceSheet = true
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                    .foregroundColor(coralColor.opacity(0.4))
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(.systemGray6).opacity(0.6))
                    )

            if let image = viewModel.coverPhotoImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else if let url = viewModel.coverPhotoURL {
                    RemoteImageView(
                        url: url,
                        contentMode: .fill,
                        showsPlaceholderIcon: true,
                        placeholderBackground: coralColor.opacity(0.15),
                        placeholderIconFont: .system(size: 28)
                    )
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(coralColor)
                            .padding(10)
                            .background(Circle().fill(coralColor.opacity(0.12)))

                        Text("Add Cover Photo")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)

                        Text("(Optional)")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }

                if viewModel.isUploadingCoverPhoto {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.black.opacity(0.35))
                    VStack(spacing: 6) {
                        ProgressView()
                            .tint(.white)
                        Text("Uploading...")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            .frame(height: 180)
        }
        .buttonStyle(.plain)
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("RECIPE NAME")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)

            TextField("e.g., Grandma's Apple Pie", text: modelBinding(\.title), axis: .vertical)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
                .focused($focusedField, equals: .name)
                .submitLabel(.done)
                .textInputAutocapitalization(.sentences)
                .lineLimit(1...3)
                .padding(.vertical, 4)
                .onSubmit {
                    dismissInputs()
                }

            Divider()
                .background(Color.gray.opacity(0.2))
        }
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Ingredients", tint: softGreen, required: true)

            VStack(spacing: 12) {
                ForEach(viewModel.ingredients) { ingredient in
                    ingredientRow(ingredient)
                        .onDrag {
                            draggingIngredient = ingredient
                            return dragProvider(for: ingredient)
                        }
                        .onDrop(
                            of: [UTType.recipeEditorItem],
                            delegate: ReorderDropDelegate(
                                item: ingredient,
                                items: modelBinding(\.ingredients),
                                draggingItem: $draggingIngredient
                            )
                        )
                }

                addRowButton(title: "Add ingredient") {
                    dismissInputs()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.ingredients.append(RecipeEditorItem(text: ""))
                    }
                }
            }
        }
    }

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Instructions", tint: coralColor, required: true)

            VStack(spacing: 14) {
                ForEach(Array(viewModel.instructions.enumerated()), id: \.element.id) { index, instruction in
                    instructionRow(instruction, step: index + 1)
                        .onDrag {
                            draggingInstruction = instruction
                            return dragProvider(for: instruction)
                        }
                        .onDrop(
                            of: [UTType.recipeEditorItem],
                            delegate: ReorderDropDelegate(
                                item: instruction,
                                items: modelBinding(\.instructions),
                                draggingItem: $draggingInstruction
                            )
                        )
                }

                addRowButton(title: "Add next step") {
                    dismissInputs()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.instructions.append(RecipeEditorItem(text: ""))
                    }
                }
            }
        }
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Details", tint: Color.gray.opacity(0.6), required: false)

            HStack(spacing: 14) {
                detailCard(
                    title: "Prep Time",
                    value: viewModel.formattedPrepTime,
                    systemImage: "clock",
                    highlight: softGreen
                ) {
                    dismissInputs()
                    showTimePicker = true
                }

                caloriesCard
            }
        }
    }

    private func sectionHeader(title: String, tint: Color, required: Bool) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(tint)
                .frame(width: 4, height: 24)

            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)

            if required {
                Text("*")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(coralColor)
            }

            Spacer()
        }
    }

    private func ingredientRow(_ ingredient: RecipeEditorItem) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(softGreen.opacity(0.2))
                .frame(width: 28, height: 28)
                .overlay(
                    Circle()
                        .fill(softGreen)
                        .frame(width: 6, height: 6)
                )

            GrowingTextInput(
                text: binding(for: ingredient, in: modelBinding(\.ingredients)),
                placeholder: "Ingredient",
                font: .systemFont(ofSize: 16),
                textColor: .label
            ) {
                dismissInputs()
            }

            Button {
                dismissInputs()
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.ingredients.removeAll { $0.id == ingredient.id }
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(6)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray6).opacity(0.7))
        )
    }

    private func instructionRow(_ instruction: RecipeEditorItem, step: Int) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(softGreen.opacity(0.15))
                    .frame(width: 32, height: 32)

                Text("\(step)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(softGreen)
            }

            GrowingTextInput(
                text: binding(for: instruction, in: modelBinding(\.instructions)),
                placeholder: "Instruction",
                font: .systemFont(ofSize: 16),
                textColor: .label
            ) {
                dismissInputs()
            }

            Button {
                dismissInputs()
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.instructions.removeAll { $0.id == instruction.id }
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(6)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray6).opacity(0.7))
        )
    }

    private func addRowButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [6]))
            )
        }
        .buttonStyle(.plain)
    }

    private var caloriesCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "flame")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(coralColor)
            Text("CALORIES")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
            HStack(spacing: 4) {
                TextField(
                    "",
                    text: modelBinding(\.caloriesText),
                    prompt: Text("0").foregroundColor(.primary)
                )
                .keyboardType(.numberPad)
                .focused($focusedField, equals: .calories)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .frame(minWidth: 28, maxWidth: 80)
                Text("kcal")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemGray6).opacity(0.7))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            showTimePicker = false
            focusedField = .calories
        }
    }

    private func detailCard(
        title: String,
        value: String,
        systemImage: String,
        highlight: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            detailCardBody(
                title: title,
                value: value,
                systemImage: systemImage,
                highlight: highlight
            )
        }
        .buttonStyle(.plain)
    }

    private func detailCardBody(
        title: String,
        value: String,
        systemImage: String,
        highlight: Color
    ) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(highlight)
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemGray6).opacity(0.7))
        )
    }

    private func dragProvider(for item: RecipeEditorItem) -> NSItemProvider {
        let data = item.id.uuidString.data(using: .utf8)
        return NSItemProvider(item: data as NSData?, typeIdentifier: UTType.recipeEditorItem.identifier)
    }

    private func dismissInputs() {
        focusedField = nil
        showTimePicker = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .shakeDetectorRestore, object: nil)
        }
    }

    private func binding(
        for item: RecipeEditorItem,
        in items: Binding<[RecipeEditorItem]>
    ) -> Binding<String> {
        Binding(
            get: {
                items.wrappedValue.first(where: { $0.id == item.id })?.text ?? ""
            },
            set: { newValue in
                var updatedItems = items.wrappedValue
                if let index = updatedItems.firstIndex(where: { $0.id == item.id }) {
                    updatedItems[index].text = newValue
                    items.wrappedValue = updatedItems
                }
            }
        )
    }

    private func modelBinding<T>(_ keyPath: ReferenceWritableKeyPath<RecipeEditorViewModel, T>) -> Binding<T> {
        Binding(
            get: { viewModel[keyPath: keyPath] },
            set: { newValue in
                viewModel[keyPath: keyPath] = newValue
            }
        )
    }

    private func handleSave() async {
        guard viewModel.hasRequiredFields else { return }
        guard !viewModel.isUploadingCoverPhoto && viewModel.isCoverPhotoReadyForSave else {
            viewModel.errorMessage = "Cover photo upload isn't finished yet. Remove it or wait to finish."
            return
        }
        viewModel.isSaving = true
        defer { viewModel.isSaving = false }

        do {
            let accessToken = try await authManager.getValidAccessToken()
            switch viewModel.mode {
            case .create:
                let request = viewModel.makeCreateRequest()
                let response: RecipeCreateResponse = try await APIService.shared.postAuthenticated(
                    path: "/recipes",
                    body: request,
                    accessToken: accessToken
                )
                let createdRecipe = viewModel.makeRecipe(id: response.id, sourceType: "user")
                await savedRecipesStore.refreshAfterRecipeMutation(
                    recipe: createdRecipe,
                    authManager: authManager
                )
            case .edit(let recipe):
                let recipeId = try await savedRecipesStore.ensureEditableRecipeId(
                    for: recipe,
                    authManager: authManager
                )
                let request = viewModel.makeUpdateRequest()
                let response: RecipeUpdateResponse = try await APIService.shared.patchAuthenticated(
                    path: "/recipes/\(recipeId)",
                    body: request,
                    accessToken: accessToken
                )
                let updatedRecipe = viewModel.makeRecipe(id: response.id, sourceType: "user")
                savedRecipesStore.updateRecipe(updatedRecipe, sourceRecipeId: recipe.id)
            }
            dismiss()
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }

    private func startCoverPhotoUpload(for image: UIImage) {
        Task {
            do {
                let accessToken = try await authManager.getValidAccessToken()
                await MainActor.run {
                    viewModel.handleCoverPhotoSelection(image, accessToken: accessToken)
                }
            } catch {
                await MainActor.run {
                    viewModel.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

private struct ReorderDropDelegate<Item: Identifiable & Equatable>: DropDelegate {
    let item: Item
    @Binding var items: [Item]
    @Binding var draggingItem: Item?

    func dropEntered(info: DropInfo) {
        guard let draggingItem, draggingItem != item else { return }
        guard let fromIndex = items.firstIndex(of: draggingItem),
              let toIndex = items.firstIndex(of: item) else { return }

        if items[toIndex] != draggingItem {
            withAnimation(.easeInOut(duration: 0.15)) {
                items.move(
                    fromOffsets: IndexSet(integer: fromIndex),
                    toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
                )
            }
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingItem = nil
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

private struct TimePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var hours: Int
    @Binding var minutes: Int

    private let hourRange = Array(0...23)
    private let minuteRange = Array(0...59)

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Prep Time")
                    .font(.system(size: 18, weight: .semibold))
                    .padding(.top, 8)

                HStack(spacing: 20) {
                    Picker("Hours", selection: $hours) {
                        ForEach(hourRange, id: \.self) { hour in
                            Text("\(hour) h").tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)

                    Picker("Minutes", selection: $minutes) {
                        ForEach(minuteRange, id: \.self) { minute in
                            Text("\(minute) m").tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                .frame(maxWidth: .infinity)

                Spacer()
            }
            .padding(.horizontal, 24)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                }
            }
        }
    }
}

private struct CameraPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let parent: CameraPicker

        init(parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

private final class IntrinsicTextView: UITextView {
    private let placeholderLabel = UILabel()

    var placeholder: String? {
        didSet {
            placeholderLabel.text = placeholder
        }
    }

    var placeholderColor: UIColor = .secondaryLabel {
        didSet {
            placeholderLabel.textColor = placeholderColor
        }
    }

    override var text: String! {
        didSet {
            updatePlaceholderVisibility()
            invalidateIntrinsicContentSize()
        }
    }

    override var attributedText: NSAttributedString! {
        didSet {
            updatePlaceholderVisibility()
            invalidateIntrinsicContentSize()
        }
    }

    override var font: UIFont? {
        didSet {
            placeholderLabel.font = font
            invalidateIntrinsicContentSize()
        }
    }

    override var bounds: CGRect {
        didSet {
            if oldValue.size.width != bounds.size.width {
                invalidateIntrinsicContentSize()
            }
        }
    }

    override var intrinsicContentSize: CGSize {
        let fallbackWidth = window?.windowScene?.screen.bounds.width
            ?? superview?.bounds.width
            ?? 1
        let targetWidth = bounds.width > 0 ? bounds.width : fallbackWidth
        let size = sizeThatFits(CGSize(width: targetWidth, height: .greatestFiniteMagnitude))
        let minHeight = font?.lineHeight ?? 0
        return CGSize(width: UIView.noIntrinsicMetric, height: max(size.height, minHeight))
    }

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setupPlaceholder()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPlaceholder()
    }

    private func setupPlaceholder() {
        placeholderLabel.numberOfLines = 0
        placeholderLabel.textColor = placeholderColor
        placeholderLabel.font = font
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(placeholderLabel)
        NSLayoutConstraint.activate([
            placeholderLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            placeholderLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            placeholderLabel.topAnchor.constraint(equalTo: topAnchor)
        ])
        updatePlaceholderVisibility()
    }

    func updatePlaceholderVisibility() {
        placeholderLabel.isHidden = !text.isEmpty
    }
}

private struct GrowingTextViewRepresentable: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let font: UIFont
    let textColor: UIColor
    let onCommit: () -> Void

    func makeUIView(context: Context) -> IntrinsicTextView {
        let textView = IntrinsicTextView()
        textView.delegate = context.coordinator
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.font = font
        textView.textColor = textColor
        textView.placeholder = placeholder
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.autocapitalizationType = .sentences
        textView.returnKeyType = .done
        textView.text = text
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        textView.setContentHuggingPriority(.required, for: .vertical)
        return textView
    }

    func updateUIView(_ uiView: IntrinsicTextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        if uiView.font != font {
            uiView.font = font
        }
        if uiView.textColor != textColor {
            uiView.textColor = textColor
        }
        if uiView.placeholder != placeholder {
            uiView.placeholder = placeholder
        }
        if uiView.returnKeyType != .done {
            uiView.returnKeyType = .done
        }
        if uiView.autocapitalizationType != .sentences {
            uiView.autocapitalizationType = .sentences
        }
        uiView.updatePlaceholderVisibility()
        uiView.invalidateIntrinsicContentSize()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        private let parent: GrowingTextViewRepresentable

        init(parent: GrowingTextViewRepresentable) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            if let placeholderTextView = textView as? IntrinsicTextView {
                placeholderTextView.updatePlaceholderVisibility()
            }
            textView.invalidateIntrinsicContentSize()
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if text == "\n" {
                parent.onCommit()
                textView.resignFirstResponder()
                return false
            }
            return true
        }
    }
}

private struct GrowingTextInput: View {
    @Binding var text: String
    let placeholder: String
    let font: UIFont
    let textColor: UIColor
    let onCommit: () -> Void

    var body: some View {
        GrowingTextViewRepresentable(
            text: $text,
            placeholder: placeholder,
            font: font,
            textColor: textColor,
            onCommit: onCommit
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    NavigationStack {
        RecipeEditorView(mode: .create)
    }
    .environment(AuthenticationManager())
    .environment(SavedRecipesStore.preview())
}
