//
//  SubscriptionManager.swift
//  SpotClock
//
//  Created by Gerard Gomez on 10/12/25.
//


import StoreKit
import SwiftUI

@MainActor
@Observable
final class SubscriptionService {
    // MARK: - Access
    var hasProAccess = false
    
    // MARK: - Free tier tracking
    var monthlySessionsUsed = 0
    var currentMonthStart = Date()
    private let maxFreeSessions = 3
    
    // Your subscription group id from ASC / StoreKit config
    let subscriptionGroupID = "21805417"
    
    init() {
        loadSessionCount()
        
        // Establish entitlement once at launch
        Task { await refreshEntitlements() }
        
        // Listen for any subsequent transaction changes (upgrades, renewals, restores)
        Task {
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                // Only react to transactions from our group
                if transaction.subscriptionGroupID == subscriptionGroupID {
                    await refreshEntitlements()
                }
                await transaction.finish()
            }
        }
    }
    
    // MARK: - UI helpers
    var canStartSession: Bool { hasProAccess || monthlySessionsUsed < maxFreeSessions }
    var sessionsRemaining: Int { max(0, maxFreeSessions - monthlySessionsUsed) }
    
    func recordSession() {
        checkAndResetMonth()
        monthlySessionsUsed += 1
        saveSessionCount()
    }
    
    // MARK: - Purchase flow (call this from your Paywall)
    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
                case .success(let verification):
                    if case .verified(let transaction) = verification {
                        // Immediately refresh entitlements based on the returned transaction
                        await refreshEntitlements(using: transaction)
                        await transaction.finish()
                    }
                case .userCancelled, .pending:
                    break
                @unknown default:
                    break
            }
        } catch {
            // handle purchase error (optional logging/UI)
        }
    }
    
    // MARK: - Restore
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            // optional: surface restore error
        }
    }
    
    // MARK: - Entitlements
    /// Re-compute `hasProAccess` using either a just-returned transaction or by scanning current entitlements.
    private func refreshEntitlements(using transaction: StoreKit.Transaction? = nil) async {
        if let transaction {
            hasProAccess = isActivePro(transaction)
            return
        }
        
        var isPro = false
        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let tx) = entitlement else { continue }
            if isActivePro(tx) {
                isPro = true
                break
            }
        }
        hasProAccess = isPro
    }
    
    /// Returns true when the transaction is from our sub group and currently active.
    private func isActivePro(_ tx: StoreKit.Transaction) -> Bool {
        guard tx.productType == .autoRenewable,
              tx.subscriptionGroupID == subscriptionGroupID else { return false }
        // active if not revoked and not expired
        if let revocationDate = tx.revocationDate, revocationDate <= Date() { return false }
        if let expiration = tx.expirationDate, expiration <= Date() { return false }
        return true
    }
    
    // MARK: - Month bookkeeping
    private func checkAndResetMonth() {
        let cal = Calendar.current
        if !cal.isDate(currentMonthStart, equalTo: Date(), toGranularity: .month) {
            monthlySessionsUsed = 0
            currentMonthStart = Date()
            saveSessionCount()
        }
    }
    
    private func loadSessionCount() {
        if let data = UserDefaults.standard.data(forKey: "sessionData"),
           let decoded = try? JSONDecoder().decode(SessionData.self, from: data) {
            monthlySessionsUsed = decoded.count
            currentMonthStart = decoded.monthStart
            checkAndResetMonth()
        }
    }
    
    private func saveSessionCount() {
        let data = SessionData(count: monthlySessionsUsed, monthStart: currentMonthStart)
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: "sessionData")
        }
    }
}

