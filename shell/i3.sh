#!/usr/bin/env bash

get_scratchpad_name() {
    i3-msg -t get_tree | jq -r '.. | .nodes? // empty | .[] | select(.name == "__i3_scratch") |
        (.floating_nodes + .nodes) | .. | .name? // empty'
}

get_scratchpad_class() {
    i3-msg -t get_tree | jq -r '.. | .nodes? // empty | .[] | select(.name == "__i3_scratch") |
        (.floating_nodes + .nodes) | .. | .window_properties? | .class? // empty'
}
