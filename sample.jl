doc = """SoftConfidenceWeighted sample

Usage:
  sample.jl [-c  <conf>]
  sample.jl [--confidence <conf>]
  sample.jl [-a <agr>]
  sample.jl [--aggressiveness <agr>]
  sample.jl -h | --help

Options:
  -h --help                         Show this screen.
  -c <conf>, --confidence=<conf>    Confidence parameter [default: 0.7].
  -a <agr>, --aggressiveness=<agr>  Aggressiveness parameter [default: 0.7].
"""

using DocOpt
using SoftConfidenceWeighted
using JSON

arguments = docopt(doc)
confidence = float(arguments["--confidence"])
aggressiveness = float(arguments["--aggressiveness"])

scw = SCWParameter(confidence, aggressiveness)

for line in EachLine(STDIN)
  line = chomp(line)
  if line == ""
    break
  end

  label, data = JSON.parse(line)
  if int(label) == 0
    label = classify(scw, data)
    println("classify: $label $data")
  else
    update(scw, data, label)
    println("update: $label $data")
  end
end
