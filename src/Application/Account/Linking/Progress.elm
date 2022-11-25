module Account.Linking.Progress exposing (..)


type Progress
    = Consumer ConsumerStep
    | Producer ProducerStep


type ConsumerStep
    = WaitingOnProducer
    | ConsumerPin (List Int)


type ProducerStep
    = WaitingOnConsumer
    | ProducerPin (List Int)
