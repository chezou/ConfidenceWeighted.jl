module SoftConfidenceWeighted

export classify, update, SCWParameter

import DataStructures.DefaultDict

const MIN_CONFIDENCE = 0.0
const MAX_CONFIDENCE = 1.0
const DEFAULT_CONFIDENCE = 0.7
const MIN_AGGRESSIVENESS = 0.0
const DEFAULT_AGGRESSIVENESS = 1.0
const VALID_LABEL = [1, -1]
const ERF_ORDER = 30

type SCWParameter
  aggressiveness::Float64
  phi::Float64
  psi::Float64
  zeta::Float64
  mu::DefaultDict
  sigma::DefaultDict

  function SCWParameter(confidence::Float64 = 0.7, aggressiveness::Float64 = 1.0)
    if confidence < MIN_CONFIDENCE
      confidence = MIN_CONFIDENCE
    elseif confidence > MAX_CONFIDENCE
      confidence = MAX_CONFIDENCE
    end

    if aggressiveness < MIN_AGGRESSIVENESS
      aggressiveness = MIN_AGGRESSIVENESS
    end
    phi = probit(confidence)
    psi = 1.0 + phi * phi / 2.0
    zeta = 1.0 + phi * phi

    mu = DefaultDict(0.0)
    sigma = DefaultDict(1.0)

    new(aggressiveness, phi, psi, zeta, mu, sigma)
  end
end

function classify(params::SCWParameter, data::Dict)
  margin = 0.0
  for (feature, weight) = data
    if haskey(params.mu, feature)
      margin += params.mu[feature] * weight
    end
  end
  if margin > 0.0
    return 1
  end
  -1
end

function update(params::SCWParameter, data::Dict, label::Int64)
  if !in(label, VALID_LABEL)
    error("invalid label: $label")
  end

  sigma_x = get_sigma_x(params, data)
  margin_mean, variance = get_margin_mean_and_variance(params, label, data, sigma_x)

  if params.phi * sqrt(variance) <= margin_mean
    return params
  end

  alpha, beta = get_alpha_and_beta(params, margin_mean, variance)
  if alpha == 0.0 || beta == 0.0
    return params
  end

  for (feature, weight) = sigma_x
    params.mu[feature] += alpha * label * weight
    params.sigma[feature] -= beta * weight * weight
  end

  params
end

function get_sigma_x(params::SCWParameter, data::Dict)
  sigma_x = DefaultDict(1.0)
  for (feature, weight) = data
    sigma_x[feature] *= params.sigma[feature] * weight
  end
  sigma_x
end

function get_margin_mean_and_variance(params::SCWParameter, label::Int64, data::Dict, sigma_x::DefaultDict)
  margin_mean = 0.0
  variance    = 0.0
  for (feature, weight) = data
    margin_mean += params.mu[feature] * weight
    variance    += sigma_x[feature] * weight
  end
  (margin_mean * label, variance)
end

function get_alpha_and_beta(params::SCWParameter, margin_mean::Float64, variance::Float64)
  alpha_den = variance * params.zeta
  if alpha_den == 0.0
    return (0.0, 0.0)
  end

  term1 = margin_mean * params.phi / 2.0
  alpha = (-1.0 * margin_mean * params.psi + params.phi * sqrt(term1^2 + alpha_den)) / alpha_den
  if alpha <= 0.0
    return (0.0, 0.0)
  end

  if alpha >= params.aggressiveness
    alpha = params.aggressiveness
  end

  beta_num = alpha * params.phi
  term2    = variance * beta_num
  beta_den = term2 + (-1.0 * term2 + sqrt(term2^2 + 4.0 * variance)) / 2.0
  if beta_den == 0.0
    return (0.0, 0.0)
  end

  (alpha, beta_num / beta_den)
end

function probit(p)
  sqrt(2.0) * erf_inv(2.0 * p - 1.0)
end

function erf_inv(z)
  value = 1.0
  term  = 1.0
  c_memo = [1.0]

  for n in 1:ERF_ORDER
    term *= pi * z^2 / 4.0
    c = 0.0
    for m in 0:n-1
      c += c_memo[m + 1] * c_memo[n - m] / (m + 1.0) / (2.0 * m + 1.0)
    end
    push!(c_memo, c)
    value += c * term / (2.0 * n + 1.0)
  end
  sqrt(pi) * z * value / 2.0
end
end
