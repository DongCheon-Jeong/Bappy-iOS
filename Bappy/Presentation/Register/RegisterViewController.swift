//
//  RegisterNameViewController.swift
//  Bappy
//
//  Created by 정동천 on 2022/05/10.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class RegisterViewController: UIViewController {
    
    // MARK: Properties
    private let viewModel: RegisterViewModel
    private let disposeBag = DisposeBag()
    
    private let backButton = UIButton()
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let progressBarView: ProgressBarView
    private let continueButtonView: ContinueButtonView
    
    private let nameView: RegisterNameView
    private let genderView: RegisterGenderView
    private let birthView: RegisterBirthView
    private let nationalityView: RegisterNationalityView
    
    // MARK: Lifecycle
    init(viewModel: RegisterViewModel) {
        let nameViewModel = viewModel.subViewModels.nameViewModel
        let genderViewModel = viewModel.subViewModels.genderViewModel
        let birthViewModel = viewModel.subViewModels.birthViewModel
        let nationalityViewModel = viewModel.subViewModels.nationalityViewModel
        let progressBarViewModel = viewModel.subViewModels.progressBarViewModel
        let continueButtonViewModel = viewModel.subViewModels.continueButtonViewModel
        
        self.viewModel = viewModel
        self.nameView = RegisterNameView(viewModel: nameViewModel)
        self.genderView = RegisterGenderView(viewModel: genderViewModel)
        self.birthView = RegisterBirthView(viewModel: birthViewModel)
        self.nationalityView = RegisterNationalityView(viewModel: nationalityViewModel)
        self.progressBarView = ProgressBarView(viewModel: progressBarViewModel)
        self.continueButtonView = ContinueButtonView(viewModel: continueButtonViewModel)
        
        super.init(nibName: nil, bundle: nil)
        
        configure()
        layout()
        addKeyboardObserver()
        addTapGestureOnScrollView()
        bind()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        progressBarView.initializeProgression(1.0/4.0)
    }

    // MARK: Events
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        view.endEditing(true)
    }
    
    @objc
    private func touchesScrollView() {
        view.endEditing(true)
    }
    
    // MARK: Actions
    @objc
    private func keyboardHeightObserver(_ notification: NSNotification) {
        guard let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        let keyboardHeight = view.frame.height - keyboardFrame.minY
        let bottomPadding = (keyboardHeight != 0) ? view.safeAreaInsets.bottom : view.safeAreaInsets.bottom * 2.0 / 3.0

        UIView.animate(withDuration: 0.4) {
            self.continueButtonView.snp.updateConstraints {
                $0.bottom.equalTo(self.view.safeAreaLayoutGuide).offset(bottomPadding - keyboardHeight)
            }
            self.view.layoutIfNeeded()
        }
        
        let bottomButtonHeight = keyboardHeight + continueButtonView.frame.height
        nameView.updateTextFieldPosition(bottomButtonHeight: bottomButtonHeight)
    }
    
    // MARK: Helpers
    private func addTapGestureOnScrollView() {
        let scrollViewTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(touchesScrollView))
        scrollView.addGestureRecognizer(scrollViewTapRecognizer)
    }

    private func addKeyboardObserver() {
//        NotificationCenter.default.rx.no
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardHeightObserver), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardHeightObserver), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    private func configure() {
        view.backgroundColor = .white
        backButton.setImage(UIImage(named: "chevron_back"), for: .normal)
        backButton.imageEdgeInsets = .init(top: 13.0, left: 16.5, bottom: 13.0, right: 16.5)
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isScrollEnabled = false
        nationalityView.delegate = self
    }
    
    private func layout() {
        view.addSubview(progressBarView)
        progressBarView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
        }
        
        view.addSubview(backButton)
        backButton.snp.makeConstraints {
            $0.top.equalTo(progressBarView.snp.bottom).offset(15.0)
            $0.leading.equalToSuperview().inset(5.5)
            $0.width.height.equalTo(44.0)
        }

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.top.equalTo(backButton.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalToSuperview()
        }
        
        view.addSubview(nameView)
        nameView.snp.makeConstraints {
            $0.top.leading.bottom.equalTo(contentView)
            $0.width.equalTo(view.frame.width)
        }
        
        view.addSubview(genderView)
        genderView.snp.makeConstraints {
            $0.top.bottom.equalTo(contentView)
            $0.width.equalTo(view.frame.width)
            $0.leading.equalTo(nameView.snp.trailing)
        }
        
        view.addSubview(birthView)
        birthView.snp.makeConstraints {
            $0.top.bottom.equalTo(contentView)
            $0.width.equalTo(view.frame.width)
            $0.leading.equalTo(genderView.snp.trailing)
        }
        
        view.addSubview(nationalityView)
        nationalityView.snp.makeConstraints {
            $0.top.bottom.trailing.equalTo(contentView)
            $0.width.equalTo(view.frame.width)
            $0.leading.equalTo(birthView.snp.trailing)
        }
        
        view.addSubview(continueButtonView)
        continueButtonView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(bottomPadding * 2.0 / 3.0)
        }
    }
}

// MARK: - Bind
extension RegisterViewController {
    private func bind() {
        backButton.rx.tap
            .bind(to: viewModel.input.backButtonTapped)
            .disposed(by: disposeBag)
        
        viewModel.output.shouldKeyboardHide
            .emit(to: view.rx.endEditing)
            .disposed(by: disposeBag)
        
        viewModel.output.pageContentOffset
            .drive(scrollView.rx.setContentOffset)
            .disposed(by: disposeBag)

        viewModel.output.shouldKeyboardHide
            .emit(to: view.rx.endEditing)
            .disposed(by: disposeBag)

        viewModel.output.progression
            .drive(progressBarView.rx.setProgression)
            .disposed(by: disposeBag)
        
        viewModel.output.popView
            .emit(onNext: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - Binder
// MainScheduler에서 수행, Observer only -> 값을 주입할 수 있지만, 값을 관찰할 수 없음
extension Reactive where Base: UIScrollView {
    var setContentOffset: Binder<CGPoint> {
        return Binder(self.base) { scrollView, offset in
            scrollView.setContentOffset(offset, animated: true)
        }
    }
}

extension Reactive where Base: UIView {
    var endEditing: Binder<Void> {
        return Binder(self.base) { view, _ in
            view.endEditing(true)
        }
    }
}

// MARK: - RegisterNationalityViewDelegate
extension RegisterViewController: RegisterNationalityViewDelegate {
    func showSelectNationalityView() {
        view.endEditing(true) // 임시
        let viewController = SelectNationalityViewController()
        viewController.modalPresentationStyle = .overCurrentContext
        viewController.delegate = self
        present(viewController, animated: false, completion: nil)
    }
}

// MARK: - SelectNationalityViewControllerDelegate
extension RegisterViewController: SelectNationalityViewControllerDelegate {
    func getSelectedCountry(_ country: Country) {
        nationalityView.country = country
    }
}
