#!/bin/bash

API_KEY="sk-tinyfish-yB47wTLrChHle7HtZUu6uwG9_9jRh8Cr"
ENDPOINT="https://agent.tinyfish.ai/v1/automation/run-sse"

run_agent() {
    local url="$1"
    local goal="$2"
    local response=$(curl -s -N -X POST "$ENDPOINT" \
      -H "X-API-Key: $API_KEY" \
      -H "Content-Type: application/json" \
      -d "{
        \"url\": \"$url\",
        \"goal\": \"$goal\"
      }" | grep -oP '{.*}')
    echo "$response"
}

extract_field() {
    local json="$1"
    local field="$2"
    echo "$json" | jq -r ".result.$field // \"N/A\""
}

print_section() {
    local product="$1"
    local amazon_price="$2"
    local amazon_rate="$3"
    local flip_price="$4"
    local flip_rate="$5"
    local rel_price="$6"
    local rel_rate="$7"

    echo "=========================================================="
    echo "PRODUCT: $product"
    echo
    echo "Amazon:    $amazon_price    ($amazon_rate)"
    echo "Flipkart:  $flip_price      ($flip_rate)"
    echo "Reliance:  $rel_price       ($rel_rate)"
    echo

    prices=("$amazon_price" "$flip_price" "$rel_price")
    sites=("Amazon" "Flipkart" "Reliance")

    min_index=0
    for i in 1 2; do
        if [[ "${prices[$i]}" =~ ^₹?[0-9] ]]; then
            if (( ${prices[$i]//[^0-9]/} < ${prices[$min_index]//[^0-9]/} )); then
                min_index=$i
            fi
        fi
    done

    echo "CHEAPEST → ${sites[$min_index]}"
    echo "=========================================================="
    echo

    echo "${sites[$min_index]}"
}

# JSON OUTPUT FILE
JSON_OUTPUT="report.json"
echo "{}" > $JSON_OUTPUT

add_to_json() {
    local product="$1"
    local amazon_price="$2"
    local amazon_rate="$3"
    local flip_price="$4"
    local flip_rate="$5"
    local rel_price="$6"
    local rel_rate="$7"
    local cheapest="$8"

    jq \
      --arg p "$product" \
      --arg ap "$amazon_price" --arg ar "$amazon_rate" \
      --arg fp "$flip_price" --arg fr "$flip_rate" \
      --arg rp "$rel_price" --arg rr "$rel_rate" \
      --arg ch "$cheapest" \
      '
      .[$p] = {
        "Amazon": { "price": $ap, "rating": $ar },
        "Flipkart": { "price": $fp, "rating": $fr },
        "Reliance": { "price": $rp, "rating": $rr },
        "cheapest": $ch
      }
      ' $JSON_OUTPUT > tmp.$$.json && mv tmp.$$.json $JSON_OUTPUT
}

########################
# PRODUCT 1 — iPhone 15
########################
product="iPhone 15 128GB Blue"

echo "Running Amazon for $product..."
a=$(run_agent "https://www.amazon.in" "Search for iPhone 15 128GB Blue. Open first product. Extract title, price, rating. Respond in JSON.")
ap=$(extract_field "$a" "price")
ar=$(extract_field "$a" "rating")

echo "Running Flipkart..."
f=$(run_agent "https://www.flipkart.com" "Search for iPhone 15 128GB Blue. Open first product. Extract title, price, rating. Respond in JSON.")
fp=$(extract_field "$f" "price")
fr=$(extract_field "$f" "rating")

echo "Running Reliance..."
r=$(run_agent "https://www.reliancedigital.in" "Search for iPhone 15 128GB Blue. Open first product. Extract title, price, rating. Respond in JSON.")
rp=$(extract_field "$r" "price")
rr=$(extract_field "$r" "rating")

cheapest=$(print_section "$product" "$ap" "$ar" "$fp" "$fr" "$rp" "$rr")
add_to_json "$product" "$ap" "$ar" "$fp" "$fr" "$rp" "$rr" "$cheapest"

############################
# PRODUCT 2 — Samsung S24
############################
product="Samsung S24 128GB Black"

echo "Running Amazon for $product..."
a=$(run_agent "https://www.amazon.in" "Search for Samsung S24 128GB Black. Open first product. Extract title, price, rating. Respond in JSON.")
ap=$(extract_field "$a" "price")
ar=$(extract_field "$a" "rating")

echo "Running Flipkart..."
f=$(run_agent "https://www.flipkart.com" "Search for Samsung S24 128GB Black. Open first product. Extract title, price, rating. Respond in JSON.")
fp=$(extract_field "$f" "price")
fr=$(extract_field "$f" "rating")

echo "Running Reliance..."
r=$(run_agent "https://www.reliancedigital.in" "Search for Samsung S24 128GB Black. Open first product. Extract title, price, rating. Respond in JSON.")
rp=$(extract_field "$r" "price")
rr=$(extract_field "$r" "rating")

cheapest=$(print_section "$product" "$ap" "$ar" "$fp" "$fr" "$rp" "$rr")
add_to_json "$product" "$ap" "$ar" "$fp" "$fr" "$rp" "$rr" "$cheapest"

###############################################
# PRODUCT 3 — MacBook Air M2 13-inch 8/256GB
###############################################
product="MacBook Air M2 13-inch 8GB/256GB"

echo "Running Amazon for $product..."
a=$(run_agent "https://www.amazon.in" "Search for MacBook Air M2 13-inch 8GB 256GB. Open first product. Extract title, price, rating. Respond in JSON.")
ap=$(extract_field "$a" "price")
ar=$(extract_field "$a" "rating")

echo "Running Flipkart..."
f=$(run_agent "https://www.flipkart.com" "Search for MacBook Air M2 13-inch 8GB 256GB. Open first product. Extract title, price, rating. Respond in JSON.")
fp=$(extract_field "$f" "price")
fr=$(extract_field "$f" "rating")

echo "Running Reliance..."
r=$(run_agent "https://www.reliancedigital.in" "Search for MacBook Air M2 13-inch 8GB 256GB. Open first product. Extract title, price, rating. Respond in JSON.")
rp=$(extract_field "$r" "price")
rr=$(extract_field "$r" "rating")

cheapest=$(print_section "$product" "$ap" "$ar" "$fp" "$fr" "$rp" "$rr")
add_to_json "$product" "$ap" "$ar" "$fp" "$fr" "$rp" "$rr" "$cheapest"

echo "✅ JSON report saved to report.json"
