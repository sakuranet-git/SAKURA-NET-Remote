use base::message_proto::{message, misc, ChatMessage, Message, Misc};
use hbb_common::protobuf::Message as _;

// Exercise the same envelope constructed by both the session and connection handlers.
// Does not stand in for a UI session, delivery acknowledgement, or chat history.
#[test]
fn chat_wire_preserves_multiline_unicode_and_repeated_messages() {
    let lines = ["テストです🌸\n2行目", "同じ本文", "同じ本文"];
    let received: Vec<_> = lines
        .iter()
        .map(|text| {
            let mut body = Misc::new();
            body.set_chat_message(ChatMessage {
                text: text.to_string(),
                ..Default::default()
            });
            let mut envelope = Message::new();
            envelope.set_misc(body);
            let wire = envelope.write_to_bytes().unwrap();
            match Message::parse_from_bytes(&wire).unwrap().union {
                Some(message::Union::Misc(value)) => match value.union {
                    Some(misc::Union::ChatMessage(chat)) => chat.text,
                    _ => panic!("lost chat payload"),
                },
                _ => panic!("lost misc envelope"),
            }
        })
        .collect();
    assert_eq!(received, lines);
}
