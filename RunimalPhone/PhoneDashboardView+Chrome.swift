import SwiftUI

extension PhoneDashboardView {
    var pageHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("RUNIMAL")
                        .font(.title3.monospaced().weight(.black))
                        .tracking(1.6)
                        .foregroundStyle(GameBoyPalette.darkest)
                    Text("DIGITAL FIELD GUIDE")
                        .font(.caption2.monospaced().weight(.black))
                        .tracking(1.4)
                        .foregroundStyle(GameBoyPalette.mediumDark)
                }

                Spacer()

                RunimalSignalBadge(
                    icon: "sparkles",
                    label: store.weeklyBoard.season.title,
                    accent: store.pet.accentColor
                )
            }

            HStack(spacing: 6) {
                pagePill(title: "동행", icon: "sparkles", tag: 0)
                pagePill(title: "러닝", icon: "figure.run", tag: 1)
                pagePill(title: "보관함", icon: "shippingbox.fill", tag: 2)
                pagePill(title: "도감", icon: "book.closed.fill", tag: 3)
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(
            Rectangle()
                .fill(GameBoyPalette.lightest.opacity(0.92))
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(GameBoyPalette.darkest)
                        .frame(height: 2)
                }
        )
    }

    var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(Array(pageTitles.enumerated()), id: \.offset) { index, title in
                VStack(spacing: 4) {
                    Rectangle()
                        .fill(selectedTab == index ? GameBoyPalette.darkest : GameBoyPalette.mediumLight)
                        .frame(width: selectedTab == index ? 28 : 10, height: 5)
                        .overlay(
                            Rectangle()
                                .stroke(GameBoyPalette.darkest, lineWidth: selectedTab == index ? 0 : 1)
                        )
                    Text(title)
                        .font(.caption2.monospaced().weight(selectedTab == index ? .black : .medium))
                        .foregroundStyle(selectedTab == index ? GameBoyPalette.darkest : GameBoyPalette.mediumDark)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }

    func pagePill(title: String, icon: String, tag: Int) -> some View {
        let isActive = selectedTab == tag

        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                selectedTab = tag
            }
        } label: {
            HStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .black))
                    .frame(width: 10)
                Text(title)
                    .fontWeight(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.45)
                    .allowsTightening(true)
                    .layoutPriority(1)
            }
            .font(.system(size: 11, weight: .black, design: .monospaced))
            .foregroundStyle(isActive ? GameBoyPalette.lightest : GameBoyPalette.darkest)
            .padding(.horizontal, 5)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 36)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isActive ? GameBoyPalette.mediumDark : GameBoyPalette.lightest)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(GameBoyPalette.darkest, lineWidth: 2)
            )
            .overlay(alignment: .topLeading) {
                Rectangle()
                    .fill(store.pet.accentColor.opacity(0.82))
                    .frame(width: isActive ? 14 : 9, height: 4)
                    .padding(6)
            }
        }
        .buttonStyle(.plain)
    }
}
