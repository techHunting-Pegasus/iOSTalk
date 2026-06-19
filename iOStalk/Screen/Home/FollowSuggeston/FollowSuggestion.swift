//
//  FollowSuggestion.swift
//  iOStalk
//
//  Created by Ishpreet  singh on 19/01/26.
//

import SwiftUI

struct FollowSuggestion: View {
    
    @StateObject private var viewModel = FollowSuggestionViewModal()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        AppBackgroundView {
            VStack(spacing: 12) {
                headerView
                
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .padding(.top, 24)
                }
                
                ScrollView {
                    VStack(spacing: 18) {
                        if !viewModel.incomingFollowRequests.isEmpty {
                            sectionContainer(title: "Follow Requests") {
                                ForEach(viewModel.incomingFollowRequests) { user in
                                    FollowRequestRow(
                                        user: user,
                                        onAccept: { viewModel.acceptFollowRequest(from: user) },
                                        onReject: { viewModel.rejectFollowRequest(from: user) }
                                    )
                                }
                            }
                        }
                        
                        if !viewModel.incomingFriendRequests.isEmpty {
                            sectionContainer(title: "Friend Requests") {
                                ForEach(viewModel.incomingFriendRequests) { user in
                                    FriendRequestRow(
                                        user: user,
                                        onAccept: { viewModel.acceptFriendRequest(from: user) },
                                        onReject: { viewModel.rejectFriendRequest(from: user) }
                                    )
                                }
                            }
                        }
                        
                        sectionContainer(title: "Discover People") {
                            ForEach(viewModel.users) { user in
                                DiscoverUserRow(
                                    user: user,
                                    relationshipState: viewModel.relationshipState(for: user),
                                    onFollow: { viewModel.sendFollowRequest(to: user) },
                                    onUnfollow: { viewModel.unfollow(user: user) },
                                    onSendFriendRequest: { viewModel.sendFriendRequest(to: user) },
                                    onUnfriend: { viewModel.unfriend(user: user) },
                                    onAcceptFollow: { viewModel.acceptFollowRequest(from: user) },
                                    onRejectFollow: { viewModel.rejectFollowRequest(from: user) },
                                    onAcceptFriend: { viewModel.acceptFriendRequest(from: user) },
                                    onRejectFriend: { viewModel.rejectFriendRequest(from: user) }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationBarHidden(true)
        .showErrorBanner($viewModel.errorMessage)
        .onAppear {
            viewModel.loadData()
        }
    }
    
    @ViewBuilder
    private func sectionContainer<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .foregroundStyle(.white)
                .font(.system(size: 18, weight: .bold))
                .padding(.horizontal, 4)
            
            VStack(spacing: 10) {
                content()
            }
        }
    }
    
    private var headerView: some View {
        HStack(spacing: 16) {
            Button {
                dismiss()
            } label: {
                AppImages.backbuttonImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 20)
                    .foregroundStyle(.white)
            }
            
            Text(Appstrins.followsuggestion)
                .foregroundStyle(.white)
                .font(.system(size: 22, weight: .bold))
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

private struct FollowRequestRow: View {
    let user: UserModal
    let onAccept: () -> Void
    let onReject: () -> Void
    
    var body: some View {
        BaseUserRowContainer(user: user) {
            HStack(spacing: 8) {
                ActionButton(title: "Accept", style: .primary, action: onAccept)
                ActionButton(title: "Reject", style: .destructive, action: onReject)
            }
        }
    }
}

private struct FriendRequestRow: View {
    let user: UserModal
    let onAccept: () -> Void
    let onReject: () -> Void
    
    var body: some View {
        BaseUserRowContainer(user: user) {
            HStack(spacing: 8) {
                ActionButton(title: "Accept Friend", style: .primary, action: onAccept)
                ActionButton(title: "Reject", style: .destructive, action: onReject)
            }
        }
    }
}

private struct DiscoverUserRow: View {
    let user: UserModal
    let relationshipState: RelationshipState
    let onFollow: () -> Void
    let onUnfollow: () -> Void
    let onSendFriendRequest: () -> Void
    let onUnfriend: () -> Void
    let onAcceptFollow: () -> Void
    let onRejectFollow: () -> Void
    let onAcceptFriend: () -> Void
    let onRejectFriend: () -> Void
    
    var body: some View {
        BaseUserRowContainer(user: user) {
            actionsView
        }
    }
    
    @ViewBuilder
    private var actionsView: some View {
        switch relationshipState {
        case .none:
            ActionButton(title: user.isPrivateAccount == true ? "Request" : "Follow", style: .primary, action: onFollow)
        case .followRequestedSent:
            ActionButton(title: "Requested", style: .secondary, action: onUnfollow)
        case .followRequestedReceived:
            HStack(spacing: 8) {
                ActionButton(title: "Accept", style: .primary, action: onAcceptFollow)
                ActionButton(title: "Reject", style: .destructive, action: onRejectFollow)
            }
        case .following:
            HStack(spacing: 8) {
                ActionButton(title: "Unfollow", style: .destructive, action: onUnfollow)
                ActionButton(title: "Add Friend", style: .primary, action: onSendFriendRequest)
            }
        case .followedBy:
            HStack(spacing: 8) {
                ActionButton(title: "Add Friend", style: .primary, action: onSendFriendRequest)
                ActionButton(title: "Follow Back", style: .secondary, action: onFollow)
            }
        case .friendRequestedSent:
            ActionButton(title: "Friend Requested", style: .secondary, action: {})
        case .friendRequestedReceived:
            HStack(spacing: 8) {
                ActionButton(title: "Accept Friend", style: .primary, action: onAcceptFriend)
                ActionButton(title: "Reject", style: .destructive, action: onRejectFriend)
            }
        case .friend:
            HStack(spacing: 8) {
                ActionButton(title: "Friends", style: .secondary, action: {})
                ActionButton(title: "Unfriend", style: .destructive, action: onUnfriend)
            }
        }
    }
}

private struct BaseUserRowContainer<Actions: View>: View {
    let user: UserModal
    private let actions: Actions
    
    init(user: UserModal, @ViewBuilder actions: () -> Actions) {
        self.user = user
        self.actions = actions()
    }
    
    var body: some View {
        HStack(spacing: 12) {
            CachedImageView(url: user.imgurl ?? "")
                .frame(width: 45, height: 45)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name ?? "User")
                    .foregroundStyle(.white)
                    .font(.system(size: 16, weight: .semibold))
                
                if user.isPrivateAccount == true {
                    Text("Private Account")
                        .foregroundStyle(.white.opacity(0.7))
                        .font(.system(size: 12, weight: .regular))
                }
            }
            
            Spacer(minLength: 10)
            actions
        }
        .padding(12)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct ActionButton: View {
    enum Style {
        case primary
        case secondary
        case destructive
    }
    
    let title: String
    let style: Style
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .foregroundStyle(foregroundColor)
                .background(backgroundColor)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return .blue
        case .secondary:
            return Color.white.opacity(0.18)
        case .destructive:
            return .red.opacity(0.8)
        }
    }
    
    private var foregroundColor: Color {
        .white
    }
}

#Preview {
    FollowSuggestion()
}
