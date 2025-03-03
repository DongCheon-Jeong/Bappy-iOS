//
//  ProfileViewModel.swift
//  Bappy
//
//  Created by 정동천 on 2022/06/29.
//

import UIKit
import RxSwift
import RxCocoa

enum ProfileAuthorization { case view, edit }

final class ProfileViewModel: ViewModelType {
    
    struct Dependency {
        let user: BappyUser
        let authorization: ProfileAuthorization
        let bappyAuthRepository: BappyAuthRepository
        let hangoutRepository: HangoutRepository
        
        init(user: BappyUser,
             authorization: ProfileAuthorization,
             bappyAuthRepository: BappyAuthRepository = DefaultBappyAuthRepository.shared,
             hangoutRepository: HangoutRepository = DefaultHangoutRepository()) {
            self.user = user
            self.authorization = authorization
            self.bappyAuthRepository = bappyAuthRepository
            self.hangoutRepository = hangoutRepository
        }
    }
    
    struct SubViewModels {
        let headerViewModel: ProfileHeaderViewModel
    }
    
    struct Input {
        var scrollToTop: AnyObserver<Void> // <-> Parent
        var viewWillAppear: AnyObserver<Bool> // <-> View
        var itemSelected: AnyObserver<IndexPath> // <-> View
        var settingButtonTapped: AnyObserver<Void> // <-> View
        var backButtonTapped: AnyObserver<Void> // <-> View
        var selectedIndex: AnyObserver<Int> // <-> Child
        var moreButtonTapped: AnyObserver<Void> // <-> Child
        var hangoutButtonTapped: AnyObserver<Int> // <-> Child
    }
    
    struct Output {
        var scrollToTop: Signal<Void> // <-> View
        var shouldHideSettingButton: Signal<Bool> // <-> View
        var shouldHideBackButton: Signal<Bool> // <-> View
        var hangouts: Driver<[Hangout]> // <-> View
        var hideNoHangoutsView: Signal<Bool> // <-> View
        var showSettingView: Signal<ProfileSettingViewModel?> // <-> View
        var showProfileDetailView: Signal<ProfileDetailViewModel?> // <-> View
        var showHangoutDetailView: Signal<HangoutDetailViewModel?> // <-> View
        var showAlert: Signal<Void> // <-> View
        var popView: Signal<Void> // <-> View
        var hideHolderView: Signal<Bool> // <-> View
        var showLoader: Signal<Bool> // <-> View
        var user: Driver<BappyUser?> // <-> Child
        var selectedIndex: Driver<Int> // <-> Child
        var numOfJoinedHangouts: Driver<Int?> // <-> Child
        var numOfMadeHangouts: Driver<Int?> // <-> Child
        var numOfLikedHangouts: Driver<Int?> // <-> Child
    }
    
    let dependency: Dependency
    var disposeBag = DisposeBag()
    let input: Input
    let output: Output
    let subViewModels: SubViewModels
    
    private let user$: BehaviorSubject<BappyUser?>
    private let authorization$: BehaviorSubject<ProfileAuthorization>
    private let hangouts$ = BehaviorSubject<[Hangout]>(value: [])
    private let joinedHangouts$ = BehaviorSubject<[Hangout]>(value: [])
    private let madeHangouts$ = BehaviorSubject<[Hangout]>(value: [])
    private let likedHangouts$ = BehaviorSubject<[Hangout]>(value: [])
    
    private let scrollToTop$ = PublishSubject<Void>()
    private let viewWillAppear$ = PublishSubject<Bool>()
    private let itemSelected$ = PublishSubject<IndexPath>()
    private let selectedButtonIndex$ = PublishSubject<Int>()
    private let settingButtonTapped$ = PublishSubject<Void>()
    private let backButtonTapped$ = PublishSubject<Void>()
    private let selectedIndex$ = BehaviorSubject<Int>(value: 0)
    private let moreButtonTapped$ = PublishSubject<Void>()
    private let hangoutButtonTapped$ = PublishSubject<Int>()
    
    private let showSettingView$ = PublishSubject<ProfileSettingViewModel?>()
    private let showProfileDetailView$ = PublishSubject<ProfileDetailViewModel?>()
    private let showAlert$ = PublishSubject<Void>()
    private let hideHolderView$ = PublishSubject<Bool>()
    private let showLoader$ = PublishSubject<Bool>()
    private let numOfJoinedHangouts$: BehaviorSubject<Int?>
    private let numOfMadeHangouts$: BehaviorSubject<Int?>
    private let numOfLikedHangouts$: BehaviorSubject<Int?>
    
    init(dependency: Dependency) {
        self.dependency = dependency
        self.subViewModels = SubViewModels(headerViewModel: ProfileHeaderViewModel())
        
        // MARK: Streams
        let user$ = BehaviorSubject<BappyUser?>(value: dependency.user)
        let authorization$ = BehaviorSubject<ProfileAuthorization>(value: dependency.authorization)
        let numOfJoinedHangouts$ = BehaviorSubject<Int?>(value: dependency.user.numOfJoinedHangouts)
        let numOfMadeHangouts$ = BehaviorSubject<Int?>(value: dependency.user.numOfMadeHangouts)
        let numOfLikedHangouts$ = BehaviorSubject<Int?>(value: dependency.user.numOfLikedHangouts)
        
        let scrollToTop = scrollToTop$
            .asSignal(onErrorJustReturn: Void())
        let shouldHideSettingButton = authorization$
            .map { $0 == .view }
            .asSignal(onErrorJustReturn: true)
        let hangouts = hangouts$
            .asDriver(onErrorJustReturn: [])
        let hideNoHangoutsView = hangouts$
            .map { !$0.isEmpty }
            .asSignal(onErrorJustReturn: true)
        let showSettingView = showSettingView$
            .asSignal(onErrorJustReturn: nil)
        let showProfileDetailView = showProfileDetailView$
            .asSignal(onErrorJustReturn: nil)
        let showHangoutDetailView = itemSelected$
            .withLatestFrom(Observable.combineLatest(
                user$.compactMap { $0 }, hangouts$
            )) { indexPath, element -> HangoutDetailViewModel in
                let dependency = HangoutDetailViewModel.Dependency(
                    currentUser: element.0,
                    hangout: element.1[indexPath.row])
                return HangoutDetailViewModel(dependency: dependency)
            }
            .asSignal(onErrorJustReturn: nil)
        let showAlert = showAlert$
            .asSignal(onErrorJustReturn: Void())
        let shouldHideBackButton = authorization$
            .map { $0 == .edit }
            .asSignal(onErrorJustReturn: true)
        let popView = backButtonTapped$
            .asSignal(onErrorJustReturn: Void())
        let user = user$
            .asDriver(onErrorJustReturn: nil)
        let selectedIndex = selectedIndex$
            .asDriver(onErrorJustReturn: 0)
        let hideHolderView = hideHolderView$
            .asSignal(onErrorJustReturn: true)
        let showLoader = showLoader$
            .asSignal(onErrorJustReturn: false)
        let numOfJoinedHangouts = numOfJoinedHangouts$
            .asDriver(onErrorJustReturn: dependency.user.numOfJoinedHangouts)
        let numOfMadeHangouts = numOfMadeHangouts$
            .asDriver(onErrorJustReturn: dependency.user.numOfMadeHangouts)
        let numOfLikedHangouts = numOfLikedHangouts$
            .asDriver(onErrorJustReturn: dependency.user.numOfLikedHangouts)
        
        // MARK: Input & Output
        self.input = Input(
            scrollToTop: scrollToTop$.asObserver(),
            viewWillAppear: viewWillAppear$.asObserver(),
            itemSelected: itemSelected$.asObserver(),
            settingButtonTapped: settingButtonTapped$.asObserver(),
            backButtonTapped: backButtonTapped$.asObserver(),
            selectedIndex: selectedIndex$.asObserver(),
            moreButtonTapped: moreButtonTapped$.asObserver(),
            hangoutButtonTapped: hangoutButtonTapped$.asObserver()
        )
        
        self.output = Output(
            scrollToTop: scrollToTop,
            shouldHideSettingButton: shouldHideSettingButton,
            shouldHideBackButton: shouldHideBackButton,
            hangouts: hangouts,
            hideNoHangoutsView: hideNoHangoutsView,
            showSettingView: showSettingView,
            showProfileDetailView: showProfileDetailView,
            showHangoutDetailView: showHangoutDetailView,
            showAlert: showAlert,
            popView: popView,
            hideHolderView: hideHolderView,
            showLoader: showLoader,
            user: user,
            selectedIndex: selectedIndex,
            numOfJoinedHangouts: numOfJoinedHangouts,
            numOfMadeHangouts: numOfMadeHangouts,
            numOfLikedHangouts: numOfLikedHangouts
        )
        
        // MARK: Bindind
        self.user$ = user$
        self.authorization$ = authorization$
        self.numOfJoinedHangouts$ = numOfJoinedHangouts$
        self.numOfMadeHangouts$ = numOfMadeHangouts$
        self.numOfLikedHangouts$ = numOfLikedHangouts$
        
        // 선택된 인덱스의 행아웃리스트 업데이트
        Observable
            .merge(
                Observable
                    .combineLatest(selectedIndex$, joinedHangouts$)
                    .filter { $0.0 == 0 },
                Observable
                    .combineLatest(selectedIndex$, madeHangouts$)
                    .filter { $0.0 == 1 },
                Observable
                    .combineLatest(selectedIndex$, likedHangouts$)
                    .filter { $0.0 == 2 }
            )
            .map(\.1)
            .bind(to: hangouts$)
            .disposed(by: disposeBag)
        
        // Hangouts Datasource가 업데이트 될 수 있기 때문에 더 정확하게 개수로 바인딩
        // 후에 페이징 방식으로 DataSource를 업데이트 하면 수정해야함!
        joinedHangouts$
            .skip(1)
            .map(\.count)
            .bind(to: numOfJoinedHangouts$)
            .disposed(by: disposeBag)
            
        madeHangouts$
            .skip(1)
            .map(\.count)
            .bind(to: numOfMadeHangouts$)
            .disposed(by: disposeBag)
        
        likedHangouts$
            .skip(1)
            .map(\.count)
            .bind(to: numOfLikedHangouts$)
            .disposed(by: disposeBag)
        
        // Guest 모드시 프로필 가리기위해 Alert 띄우기
        viewWillAppear$
            .take(1)
            .withLatestFrom(user$)
            .compactMap { $0 }
            .filter { $0.state == .anonymous }
            .map { _ in }
            .bind(to: showAlert$)
            .disposed(by: disposeBag)
        
        // 일반 유저
        let startFlowWithUserID = viewWillAppear$
            .withLatestFrom(user$)
            .compactMap { $0 }
            .filter { $0.state == .normal }
            .map(\.id)
            .share()
        
        // fetchJoinedHangout
        let joinedHangoutResult = startFlowWithUserID
            .map { (id: $0, profileType: Hangout.UserProfileType.Joined) }
            .flatMap(dependency.hangoutRepository.fetchHangouts)
            .do { [weak self] _ in self?.hideHolderView$.onNext(true) }
            .share()
        
        joinedHangoutResult
            .compactMap(getErrorDescription)
            .bind(to: self.rx.debugError)
            .disposed(by: disposeBag)
        
        joinedHangoutResult
            .compactMap(getValue)
            .bind(to: joinedHangouts$)
            .disposed(by: disposeBag)
        
        // fetchMadeHangout
        let madeHangoutResult = startFlowWithUserID
            .map { (id: $0, profileType: Hangout.UserProfileType.Made) }
            .flatMap(dependency.hangoutRepository.fetchHangouts)
            .share()
        
        madeHangoutResult
            .compactMap(getErrorDescription)
            .bind(to: self.rx.debugError)
            .disposed(by: disposeBag)
        
        madeHangoutResult
            .compactMap(getValue)
            .bind(to: madeHangouts$)
            .disposed(by: disposeBag)
        
        // fetchLikedHangout
        let likedHangoutResult = startFlowWithUserID
            .map { (id: $0, profileType: Hangout.UserProfileType.Liked) }
            .flatMap(dependency.hangoutRepository.fetchHangouts)
            .share()
        
        likedHangoutResult
            .compactMap(getErrorDescription)
            .bind(to: self.rx.debugError)
            .disposed(by: disposeBag)
        
        likedHangoutResult
            .compactMap(getValue)
            .bind(to: likedHangouts$)
            .disposed(by: disposeBag)
            
        // Setting 버튼 Flow - 설정 상태 불러오기
        let notificationSettingResult = settingButtonTapped$
            .do { [weak self] _ in self?.showLoader$.onNext(true) }
            .flatMap(dependency.bappyAuthRepository.fetchNotificationSetting)
            .observe(on: MainScheduler.asyncInstance)
            .do { [weak self] _ in self?.showLoader$.onNext(false) }
            .share()
        
        notificationSettingResult
            .compactMap(getErrorDescription)
            .bind(to: self.rx.debugError)
            .disposed(by: disposeBag)
        
        notificationSettingResult
            .compactMap(getValue)
            .map { setting -> ProfileSettingViewModel in
                let dependency = ProfileSettingViewModel.Dependency(
                    notificationSetting: setting)
                return ProfileSettingViewModel(dependency: dependency)
            }
            .bind(to: showSettingView$)
            .disposed(by: disposeBag)
        
        // More 버튼
        moreButtonTapped$
            .withLatestFrom(user$.compactMap { $0 })
            .map { user -> ProfileDetailViewModel in
                let dependency = ProfileDetailViewModel.Dependency(
                    user: user,
                    authorization: dependency.authorization)
                return ProfileDetailViewModel(dependency: dependency)
            }
            .bind(to: showProfileDetailView$)
            .disposed(by: disposeBag)
        
        // Child(HeaderView)
        output.selectedIndex
            .drive(subViewModels.headerViewModel.input.selectedIndex)
            .disposed(by: disposeBag)
        
        output.user
            .compactMap { $0 }
            .drive(subViewModels.headerViewModel.input.user)
            .disposed(by: disposeBag)
        
        output.numOfJoinedHangouts
            .drive(subViewModels.headerViewModel.input.numOfJoinedHangouts)
            .disposed(by: disposeBag)
        
        output.numOfMadeHangouts
            .drive(subViewModels.headerViewModel.input.numOfMadeHangouts)
            .disposed(by: disposeBag)
        
        output.numOfLikedHangouts
            .drive(subViewModels.headerViewModel.input.numOfLikedHangouts)
            .disposed(by: disposeBag)
        
        subViewModels.headerViewModel.output.moreButtonTapped
            .emit(to: input.moreButtonTapped)
            .disposed(by: disposeBag)
        
        subViewModels.headerViewModel.output.selectedButtonIndex
            .distinctUntilChanged()
            .emit(to: input.selectedIndex)
            .disposed(by: disposeBag)
    }
}
