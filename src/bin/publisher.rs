use rand::Rng;
use rdkafka::config::ClientConfig;
use rdkafka::producer::{FutureProducer, FutureRecord};
use std::time::Duration;
use tokio::time::sleep;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let bootstrap_servers = std::env::var("KAFKA_BOOTSTRAP_SERVERS")
        .unwrap_or_else(|_| "localhost:9092".to_string());
    let bootstrap_servers = bootstrap_servers
        .trim_start_matches("http://")
        .trim_start_matches("https://");

    let producer: FutureProducer = ClientConfig::new()
        .set("bootstrap.servers", bootstrap_servers)
        .set("message.timeout.ms", "5000")
        .create()?;

    let topic = "random-number";
    let mut rng = rand::thread_rng();

    println!("Publishing random numbers to topic '{}'...", topic);

    loop {
        let random_val: i32 = rng.gen_range(1..=1000);
        let payload = random_val.to_string();

        let record = FutureRecord::to(topic)
            .payload(&payload)
            .key("rand-key");

        match producer.send(record, Duration::from_secs(5)).await {
            Ok((partition, offset)) => {
                println!(
                    "Published: {} -> Partition: {}, Offset: {}",
                    random_val, partition, offset
                );
            }
            Err((err, _)) => {
                eprintln!("Failed to deliver message: {:?}", err);
            }
        }

        sleep(Duration::from_secs(1)).await;
    }
}
