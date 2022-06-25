//
//  HangoutMakeLimitView.swift
//  Bappy
//
//  Created by 정동천 on 2022/05/31.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class HangoutMakeLimitView: UIView {
    
    // MARK: Properties
    private let viewModel: HangoutMakeLimitViewModel
    private let disposeBag = DisposeBag()
    
    private let limitCaptionLabel: UILabel = {
        let label = UILabel()
        label.text = "How\nmany people?"
        label.font = .roboto(size: 36.0, family: .Bold)
        label.textColor = .bappyBrown
        label.numberOfLines = 2
        return label
    }()
    
    private let numberLabel: UILabel = {
        let label = UILabel()
        label.font = .roboto(size: 65.0, family: .Bold)
        label.textColor = .bappyBrown
        return label
    }()
    
    private let minusButton = UIButton()
    private let plusButton = UIButton()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .roboto(size: 15.0, family: .Regular)
        label.textColor = .black.withAlphaComponent(0.33)
        return label
    }()
    
    // MARK: Lifecycle
    init(viewModel: HangoutMakeLimitViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        
        configure()
        layout()
        bind()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Helpers
    private func updateMinusButtonState(isEnabled: Bool) {
        let minusButtonImage = isEnabled ? UIImage(named: "make_minus_on") : UIImage(named: "make_minus_off")
        minusButton.setImage(minusButtonImage, for: .normal)
        minusButton.isEnabled = isEnabled
    }
    
    private func updatePlusButtonState(isEnabled: Bool) {
        let plusButtonImage = isEnabled ? UIImage(named: "make_plus_on") : UIImage(named: "make_plus_off")
        plusButton.setImage(plusButtonImage, for: .normal)
        plusButton.isEnabled = isEnabled
        
    }
    
    private func configure() {
        self.backgroundColor = .white
    }
    
    private func layout() {
        self.addSubview(limitCaptionLabel)
        limitCaptionLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(24.0)
            $0.leading.equalToSuperview().inset(43.0)
        }
        
        self.addSubview(numberLabel)
        numberLabel.snp.makeConstraints {
            $0.top.equalTo(limitCaptionLabel.snp.bottom).offset(88.0)
            $0.centerX.equalToSuperview()
        }
        
        self.addSubview(minusButton)
        minusButton.snp.makeConstraints {
            $0.width.height.equalTo(44.0)
            $0.centerY.equalTo(numberLabel).offset(4.0)
            $0.centerX.equalToSuperview().offset(-80.0)
        }
        
        self.addSubview(plusButton)
        plusButton.snp.makeConstraints {
            $0.width.height.equalTo(44.0)
            $0.centerY.equalTo(minusButton)
            $0.centerX.equalToSuperview().offset(80.0)
        }
        
        self.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints {
            $0.top.equalTo(numberLabel.snp.bottom).offset(15.0)
            $0.centerX.equalToSuperview()
        }
    }
}

// MARK: - Bind
extension HangoutMakeLimitView {
    private func bind() {
        minusButton.rx.tap
            .bind(to: viewModel.input.minusButtonTapped)
            .disposed(by: disposeBag)
        
        plusButton.rx.tap
            .bind(to: viewModel.input.plusButtonTapped)
            .disposed(by: disposeBag)
        
        viewModel.output.numberText
            .emit(to: numberLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.output.description
            .emit(to: descriptionLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.output.isMinusButtonEnabled
            .emit(onNext: { [weak self] isEnabled in
                self?.updateMinusButtonState(isEnabled: isEnabled)
            })
            .disposed(by: disposeBag)
        
        viewModel.output.isPlusButtonEnabled
            .emit(onNext: { [weak self] isEnabled in
                self?.updatePlusButtonState(isEnabled: isEnabled)
            })
            .disposed(by: disposeBag)
    }
}
