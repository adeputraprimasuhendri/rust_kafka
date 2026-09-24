use rdkafka::config::ClientConfig;
use rdkafka::consumer::{Consumer, StreamConsumer};
use rdkafka::message::Message;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let bootstrap_servers = std::env::var("KAFKA_BOOTSTRAP_SERVERS")
        .unwrap_or_else(|_| "192.168.100.79:9092".to_string());
    let bootstrap_servers = bootstrap_servers
        .trim_start_matches("http://")
        .trim_start_matches("https://");

    let consumer: StreamConsumer = ClientConfig::new()
        .set("bootstrap.servers", bootstrap_servers)
        .set("group.id", "random-number-group")
        .set("enable.auto.commit", "true")
        .set("auto.offset.reset", "latest")
        .create()?;

    let topic = "random-number";
    consumer.subscribe(&[topic])?;

    println!("Subscribed to '{}'. Listening for numbers...", topic);

    loop {
        match consumer.recv().await {
            Ok(msg) => {
                if let Some(Ok(payload_str)) = msg.payload_view::<str>() {
                    match payload_str.parse::<i32>() {
                        Ok(number) => {
                            println!(
                                "Received Number: {} | Partition: {} | Offset: {}",
                                number,
                                msg.partition(),
                                msg.offset()
                            );
                        }
                        Err(_) => {
                            eprintln!("Received non-integer payload: {}", payload_str);
                        }
                    }
                }
            }
            Err(err) => {
                eprintln!("Kafka consume error: {:?}", err);
            }
        }
    }
}
