//
//  BappyAuthRepository.swift
//  Bappy
//
//  Created by 정동천 on 2022/06/28.
//

import Foundation
import RxSwift

protocol BappyAuthRepository {
    static var shared: Self { get }
    var currentUser: BehaviorSubject<BappyUser?> { get }
    func fetchCurrentUser() -> Single<Result<BappyUser, Error>>
    func fetchAnonymousUser() -> Single<BappyUser>
    func createUser(name: String, gender: Gender, birth: Date, countryCode: String) -> Single<Result<BappyUser, Error>>
    func updateProfile(affiliation: String?, introduce: String?, languages: [Language]?, personalities: [Persnoality]?, interests: [Hangout.Category]?, data: Data?) -> Single<Result<Bool, Error>>
    func updateGPSSetting(to setting: Bool) -> Single<Result<Bool, Error>>
    func updateFCMToken(_ fcmToken: String) -> Single<Result<Bool, Error>>
    func fetchUserLocations() -> Single<Result<[Location], Error>>
}
