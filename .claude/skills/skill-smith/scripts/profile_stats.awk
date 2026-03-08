#!/usr/bin/awk -f
#
# Compute summary statistics from profiling metrics.
# Input:  Tab-separated: step_number<TAB>metric_name<TAB>value
# Output: Tab-separated: step_number<TAB>metric_name<TAB>avg<TAB>median<TAB>stddev<TAB>min<TAB>max<TAB>proportion

BEGIN {
  FS = "\t"
  OFS = "\t"
  error = 0
}

{
  if (NF != 3) {
    print "error: line " NR " has " NF " fields, expected 3" > "/dev/stderr"
    error = 1
    next
  }

  step = $1
  metric = $2
  value = $3 + 0

  key = step "\t" metric
  count[key]++
  sum[key] += value
  sumsq[key] += value * value
  if (count[key] == 1 || value < min_val[key]) min_val[key] = value
  if (count[key] == 1 || value > max_val[key]) max_val[key] = value

  # Store values for median calculation
  values[key, count[key]] = value

  # Track unique keys for iteration
  if (count[key] == 1) {
    keys[++nkeys] = key
  }
}

END {
  if (error) exit 1
  if (nkeys == 0) {
    print "error: no valid data" > "/dev/stderr"
    exit 1
  }

  # Compute avg per key
  for (i = 1; i <= nkeys; i++) {
    k = keys[i]
    avg[k] = sum[k] / count[k]
  }

  # Compute total avg per metric (for proportion)
  for (i = 1; i <= nkeys; i++) {
    k = keys[i]
    split(k, parts, "\t")
    metric = parts[2]
    metric_total[metric] += avg[k]
  }

  # Output stats per key
  for (i = 1; i <= nkeys; i++) {
    k = keys[i]
    n = count[k]
    a = avg[k]

    # Stddev (population)
    variance = (sumsq[k] / n) - (a * a)
    if (variance < 0) variance = 0
    sd = sqrt(variance)

    # Median: sort values for this key (insertion sort)
    for (j = 1; j <= n; j++) sorted[j] = values[k, j]
    for (j = 2; j <= n; j++) {
      tmp = sorted[j]
      m = j - 1
      while (m >= 1 && sorted[m] > tmp) {
        sorted[m + 1] = sorted[m]
        m--
      }
      sorted[m + 1] = tmp
    }
    if (n % 2 == 1) {
      med = sorted[int(n / 2) + 1]
    } else {
      med = (sorted[n / 2] + sorted[n / 2 + 1]) / 2
    }

    # Proportion
    split(k, parts, "\t")
    metric = parts[2]
    if (metric_total[metric] > 0) {
      prop = a / metric_total[metric]
    } else {
      prop = 0
    }

    printf "%s\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.4f\n", k, a, med, sd, min_val[k], max_val[k], prop
  }
}
