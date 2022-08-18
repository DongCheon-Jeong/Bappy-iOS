//
//  HangoutMakeOpenchatViewModel.swift
//  Bappy
//
//  Created by 정동천 on 2022/06/15.
//

import UIKit
import RxSwift
import RxCocoa

final class HangoutMakeOpenchatViewModel: ViewModelType {
    
    struct Dependency {
        var openchatGuideURL: URL? {
            URL(string: "https://www.instagram.com/s/aGlnaGxpZ2h0OjE3OTE3NDU5OTgyNTc0MDEx?story_media_id=2907455711659592766_51659214498&igshid=YmMyMTA2M2Y=")
        }
    }
    
    struct Input {
        var text: AnyObserver<String> // <-> View
        var editingDidBegin: AnyObserver<Void> // <-> View
        var guideButtonTapped: AnyObserver<Void> // <-> View
        var keyboardWithButtonHeight: AnyObserver<CGFloat> // <-> Parent
    }
    
    struct Output {
        var shouldHideRule: Signal<Bool> // <-> View
        var keyboardWithButtonHeight: Signal<CGFloat> // <-> View
        var openOpenchatGuide: Signal<URL?> // <-> View
        var openchatText: Signal<String> // <-> Parent
        var isValid: Signal<Bool> // <-> Parent
    }
    
    let dependency: Dependency
    var disposeBag = DisposeBag()
    let input: Input
    let output: Output
    
    private let openchatGuideURL$: BehaviorSubject<URL?>
    
    private let text$ = BehaviorSubject<String>(value: "")
    private let editingDidBegin$ = PublishSubject<Void>()
    private let guideButtonTapped$ = PublishSubject<Void>()
    private let keyboardWithButtonHeight$ = PublishSubject<CGFloat>()
    
    init(dependency: Dependency = Dependency()) {
        self.dependency = dependency
        
        // MARK: Streams
        let openchatGuideURL$ = BehaviorSubject<URL?>(value: dependency.openchatGuideURL)
        let isOpenchatValid = text$
            .map(validation)
            .share()
        let shouldHideRule = isOpenchatValid
            .asSignal(onErrorJustReturn: false)
        let keyboardWithButtonHeight = keyboardWithButtonHeight$
            .asSignal(onErrorJustReturn: 0)
        let openOpenchatGuide = guideButtonTapped$
            .withLatestFrom(openchatGuideURL$)
            .asSignal(onErrorJustReturn: nil)
        let openchatText = text$
            .filter(validation)
            .asSignal(onErrorJustReturn: "")
        let isValid = isOpenchatValid
            .distinctUntilChanged()
            .asSignal(onErrorJustReturn: false)
        
        // MARK: Input & Output
        self.input = Input(
            text: text$.asObserver(),
            editingDidBegin: editingDidBegin$.asObserver(),
            guideButtonTapped: guideButtonTapped$.asObserver(),
            keyboardWithButtonHeight: keyboardWithButtonHeight$.asObserver()
        )
        
        self.output = Output(
            shouldHideRule: shouldHideRule,
            keyboardWithButtonHeight: keyboardWithButtonHeight,
            openOpenchatGuide: openOpenchatGuide,
            openchatText: openchatText,
            isValid: isValid
        )
        
        // MARK: Binding
        self.openchatGuideURL$ = openchatGuideURL$
    }
}

private func validation(text: String) -> Bool {
    text.count >= 4
}
