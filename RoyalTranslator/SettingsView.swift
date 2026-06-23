import SwiftUI

struct SettingsView: View {
    @Binding var isPresented: Bool
    let accent: Color
    let faded: Color
    let vellum: Color
    let inkDark: Color
    let parchment: Color

    @State private var currentIcon: String? = UIApplication.shared.alternateIconName

    var body: some View {
        ZStack {
            LinearGradient(colors: [vellum, parchment], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                HStack {
                    Text("Settings")
                        .font(.custom("Georgia", size: 22))
                        .fontWeight(.bold)
                        .foregroundColor(accent)
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .foregroundColor(faded)
                            .font(.system(size: 18))
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("App Icon")
                        .font(.custom("Georgia", size: 13))
                        .kerning(1.5)
                        .textCase(.uppercase)
                        .foregroundColor(faded)

                    HStack(spacing: 20) {
                        IconChoice(
                            label: "Royal",
                            imageName: "AppIconLight",
                            isSelected: currentIcon == nil,
                            accent: accent,
                            faded: faded
                        ) {
                            setIcon(nil)
                        }

                        IconChoice(
                            label: "Dark",
                            imageName: "AppIconDark_120",
                            isSelected: currentIcon == "AppIconDark",
                            accent: accent,
                            faded: faded
                        ) {
                            setIcon("AppIconDark")
                        }
                    }
                }
                .padding(20)
                .background(Color.white.opacity(0.4))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(faded, lineWidth: 1))

                Spacer()
            }
            .padding(28)
        }
        .font(.custom("Georgia", size: 16))
        .foregroundColor(inkDark)
    }

    private func setIcon(_ name: String?) {
        UIApplication.shared.setAlternateIconName(name) { error in
            if error == nil {
                currentIcon = name
            }
        }
    }
}

struct IconChoice: View {
    let label: String
    let imageName: String
    let isSelected: Bool
    let accent: Color
    let faded: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                if let uiImage = UIImage(named: imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(isSelected ? accent : faded, lineWidth: isSelected ? 3 : 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 80)
                }

                Text(label)
                    .font(.custom("Georgia", size: 13))
                    .foregroundColor(isSelected ? accent : faded)
            }
        }
    }
}
