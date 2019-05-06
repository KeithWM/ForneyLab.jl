@sumProductRule(:node_type     => GaussianWeightedMeanPrecision,
                :outbound_type => Message{GaussianWeightedMeanPrecision},
                :inbound_types => (Nothing, Message{PointMass}, Message{PointMass}),
                :name          => SPGaussianWeightedMeanPrecisionOutVPP)

@naiveVariationalRule(:node_type     => GaussianWeightedMeanPrecision,
                      :outbound_type => Message{GaussianWeightedMeanPrecision},
                      :inbound_types => (Nothing, ProbabilityDistribution, ProbabilityDistribution),
                      :name          => VBGaussianWeightedMeanPrecisionOut)