import Foundation
import InputBarAccessoryView
import MessageKit
import UIKit

final class ChatBotViewController: MessagesViewController {
    private struct ChatSender: SenderType {
        let senderId: String
        let displayName: String
    }

    private struct ChatMessage: MessageType {
        let sender: SenderType
        let messageId: String
        let sentDate: Date
        let kind: MessageKind
    }

    private let user = ChatSender(senderId: "user", displayName: "Bạn")
    private let bot = ChatSender(senderId: "bot", displayName: "Chatbot")
    private var messages: [ChatMessage] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Chatbot"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )

        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messagesCollectionView.backgroundColor = .backgroundHome
        messageInputBar.delegate = self
        messageInputBar.inputTextView.placeholder = "Nhập tin nhắn..."

        messages = [
            ChatMessage(
                sender: bot,
                messageId: UUID().uuidString,
                sentDate: Date(),
                kind: .text("Xin chào! Bạn cần mình hỗ trợ gì về bệnh trên lá?")
            )
        ]

        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem(animated: false)
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    private func appendMessage(_ text: String, sender: SenderType) {
        let message = ChatMessage(
            sender: sender,
            messageId: UUID().uuidString,
            sentDate: Date(),
            kind: .text(text)
        )

        messages.append(message)
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem(animated: true)
    }

    private func botReply(for text: String) {
        let normalized = text.lowercased()
        let reply: String

        if normalized.contains("chào") || normalized.contains("xin chào") {
            reply = "Xin chào bạn! Hãy gửi ảnh lá cây hoặc mô tả triệu chứng nhé."
        } else if normalized.contains("bệnh") || normalized.contains("lá") {
            reply = "Bạn có thể quay lại màn hình Home để chụp hoặc chọn ảnh rồi nhận diện bệnh."
        } else if normalized.contains("giúp") {
            reply = "Mình có thể hỗ trợ nhận diện bệnh lá, hoặc tư vấn cách dùng app."
        } else {
            reply = "Mình đã nhận tin nhắn của bạn. Nếu muốn chẩn đoán, hãy thử gửi ảnh lá cây nhé."
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self = self else { return }
            self.appendMessage(reply, sender: self.bot)
        }
    }
}

extension ChatBotViewController: MessagesDataSource {
    func currentSender() -> SenderType {
        user
    }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        messages.count
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        messages[indexPath.section]
    }

    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        return NSAttributedString(
            string: formatter.string(from: message.sentDate),
            attributes: [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.secondaryLabel
            ]
        )
    }
}

extension ChatBotViewController: MessagesDisplayDelegate {
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        avatarView.set(avatar: Avatar(image: nil, initials: String(message.sender.displayName.prefix(1))))
    }

    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        messagesCollectionView.messagesDataSource?.isFromCurrentSender(message: message) == true ? .systemBlue : .secondarySystemBackground
    }

    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        messagesCollectionView.messagesDataSource?.isFromCurrentSender(message: message) == true ? .white : .label
    }
}

extension ChatBotViewController: MessagesLayoutDelegate {}

extension ChatBotViewController: MessageCellDelegate {}

extension ChatBotViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        appendMessage(trimmed, sender: user)

        inputBar.inputTextView.text = ""
        inputBar.invalidateIntrinsicContentSize()

        botReply(for: trimmed)
    }
}
