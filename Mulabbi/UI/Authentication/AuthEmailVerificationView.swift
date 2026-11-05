//
//  AuthEmailVerificationView.swift
//  Mulabbi
//
//  Created by Yara Alsunbul on 21/05/1448 AH.
//
import SwiftUI
import FirebaseAuth

struct AuthEmailVerificationView: View {
    @AppStorage("appLanguage") private var appLanguage = "en"
    @Environment(\.dismiss) private var dismiss

    let email: String
    let onVerified: () -> Void

    @State private var message: String?
    @State private var isChecking = false
    @State private var isResending = false
    @State private var didVerify = false

    private var isArabic: Bool { appLanguage == "ar" }
    private func tr(_ en: String, _ ar: String) -> String { isArabic ? ar : en }

    var body: some View {
        ZStack {
            MulabbiAuthBackdrop()
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: isArabic ? "chevron.right" : "chevron.left")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(Color.mulabbiMaroon)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    Spacer()
                }
                .padding(.horizontal, 22)
                .padding(.top, 24)

                Spacer()

                VStack(spacing: 14) {
                    Image(systemName: didVerify ? "checkmark.seal.fill" : "envelope.badge")
                        .font(.system(size: 42))
                        .foregroundColor(Color.mulabbiMaroon)

                    Text(didVerify ? tr("Email verified", "تم تأكيد البريد") : tr("Verify your email", "أكّدي بريدك الإلكتروني"))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color.mulabbiMaroon)

                    Text(didVerify
                         ? tr("Your email is verified. You can continue.", "تم تأكيد بريدك. يمكنك المتابعة.")
                         : tr("We sent a verification link to:", "أرسلنا رابط التحقق إلى:"))
                        .font(.system(size: 13))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)

                    if !didVerify {
                        Text(email)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .textSelection(.enabled)

                        Text(tr("Open the email and tap the link, then return here.", "افتحي الرسالة واضغطي الرابط، ثم ارجعي إلى التطبيق."))
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)

                        Button(action: checkVerification) {
                            Group {
                                if isChecking { ProgressView().tint(.white) }
                                else { Text(tr("I verified my email", "تحققت من بريدي")).font(.system(size: 16, weight: .semibold)) }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.mulabbiMaroon)
                            .clipShape(Capsule())
                        }
                        .disabled(isChecking || isResending)

                        Button(action: resendLink) {
                            Text(isResending ? tr("Sending…", "جارٍ الإرسال…") : tr("Resend verification link", "إعادة إرسال رابط التحقق"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color.mulabbiMaroon)
                        }
                        .disabled(isChecking || isResending)
                    } else {
                        Button(action: onVerified) {
                            Text(tr("Continue", "متابعة"))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.mulabbiMaroon)
                                .clipShape(Capsule())
                        }
                    }

                    if let message {
                        Text(message)
                            .font(.system(size: 12))
                            .foregroundColor(Color.mulabbiMaroon)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 24)
                .frame(maxWidth: 350)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))

                Spacer()
            }
        }
        .environment(\.layoutDirection, isArabic ? .rightToLeft : .leftToRight)
        .navigationBarBackButtonHidden(true)
    }

    // هنا نتأكد من حالة البريد بعد ما يرجع المستخدم من رابط التحقق.
    private func checkVerification() {
        guard let user = Auth.auth().currentUser else {
            message = tr("Please sign in again after verifying your email.", "بعد تأكيد البريد، سجّلي الدخول مجددًا.")
            return
        }
        isChecking = true
        user.reload { error in
            isChecking = false
            if let error {
                message = error.localizedDescription
            } else if Auth.auth().currentUser?.isEmailVerified == true {
                didVerify = true
                message = nil
            } else {
                message = tr("Email is not verified yet. Open the link in your email first.", "لم يتم تأكيد البريد بعد. افتحي الرابط في رسالتك أولًا.")
            }
        }
    }

    private func resendLink() {
        guard let user = Auth.auth().currentUser else {
            message = tr("Please sign in again to resend the link.", "سجّلي الدخول مجددًا لإعادة إرسال الرابط.")
            return
        }
        isResending = true
        user.sendEmailVerification { error in
            isResending = false
            message = error.map { $0.localizedDescription }
                ?? tr("A new verification link was sent.", "أرسلنا رابط تحقق جديدًا.")
        }
    }
}
