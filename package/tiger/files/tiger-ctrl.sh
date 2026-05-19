#!/bin/sh
# tiger-ctrl.sh -- sync UCI config to TOML (called from tiger.init start_service)

readonly CONF_DIR="/etc/tuic"
readonly CONF_FILE="$CONF_DIR/config.toml"

# JSON-escape for TOML string values
toml_esc() {
	printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

# Convert UCI 1/0 to TOML true/false
toml_bool() {
	case "$1" in
		1|true|yes|on) echo "true" ;;
		*) echo "false" ;;
	esac
}

sync_config() {
	local server udp_relay_ipv6 zero_rtt_handshake dual_stack
	local auth_timeout stream_timeout gc_interval gc_lifetime
	local self_sign hostname certificate private_key auto_ssl acme_email alpn
	local congestion_control initial_mtu min_mtu send_window receive_window max_idle_time
	local restful_addr restful_secret max_clients

	# ── 基本 ──
	server=$(uci -q get tiger.server.server);         server="${server:-[::]:8443}"
	# 清除前导/尾随空格
	server=$(printf '%s' "$server" | xargs)
	udp_relay_ipv6=$(uci -q get tiger.server.udp_relay_ipv6);    udp_relay_ipv6="${udp_relay_ipv6:-1}"
	zero_rtt_handshake=$(uci -q get tiger.server.zero_rtt_handshake);   zero_rtt_handshake="${zero_rtt_handshake:-0}"
	dual_stack=$(uci -q get tiger.server.dual_stack); dual_stack="${dual_stack:-1}"
	auth_timeout=$(uci -q get tiger.server.auth_timeout);     auth_timeout="${auth_timeout:-3}"
	stream_timeout=$(uci -q get tiger.server.stream_timeout);   stream_timeout="${stream_timeout:-60}"
	gc_interval=$(uci -q get tiger.server.gc_interval);      gc_interval="${gc_interval:-10}"
	gc_lifetime=$(uci -q get tiger.server.gc_lifetime);      gc_lifetime="${gc_lifetime:-30}"

	# ── TLS ──
	self_sign=$(uci -q get tiger.server.self_sign);    self_sign="${self_sign:-1}"
	hostname=$(uci -q get tiger.server.hostname);      hostname="${hostname:-localhost}"
	certificate=$(uci -q get tiger.server.certificate); certificate="${certificate:-}"
	private_key=$(uci -q get tiger.server.private_key); private_key="${private_key:-}"
	auto_ssl=$(uci -q get tiger.server.auto_ssl);       auto_ssl="${auto_ssl:-0}"
	acme_email=$(uci -q get tiger.server.acme_email);   acme_email="${acme_email:-}"
	alpn=$(uci -q get tiger.server.alpn);                alpn="${alpn:-h3}"

	# ── QUIC ──
	congestion_control=$(uci -q get tiger.server.congestion_control); congestion_control="${congestion_control:-bbr}"
	initial_mtu=$(uci -q get tiger.server.initial_mtu);   initial_mtu="${initial_mtu:-1200}"
	min_mtu=$(uci -q get tiger.server.min_mtu);           min_mtu="${min_mtu:-1200}"
	send_window=$(uci -q get tiger.server.send_window);   send_window="${send_window:-16777216}"
	receive_window=$(uci -q get tiger.server.receive_window); receive_window="${receive_window:-8388608}"
	max_idle_time=$(uci -q get tiger.server.max_idle_time); max_idle_time="${max_idle_time:-30}"

	# ── RESTful API ──
	restful_addr=$(uci -q get tiger.server.restful_addr)
	restful_secret=$(uci -q get tiger.server.restful_secret)
	max_clients=$(uci -q get tiger.server.max_clients);   max_clients="${max_clients:-0}"

	# ── 用户（动态收集所有 user 节） ──
	local users=""
	local count=0
	while true; do
		uuid=$(uci -q get "tiger.@user[${count}].uuid")
		pw=$(uci -q get "tiger.@user[${count}].password")
		[ -z "$uuid" ] && [ -z "$pw" ] && break
		[ -n "$uuid" ] && [ -n "$pw" ] && {
			users="${users}\"$(toml_esc "$uuid")\" = \"$(toml_esc "$pw")\"\n"
		}
		count=$((count + 1))
	done

	mkdir -p "$CONF_DIR"

	cat > "$CONF_FILE" <<-CONF
		# Tiger (TUIC Server) — 由 UCI 自动同步
		# 手动修改将被覆盖！

		log_level = "info"
		server = "$(toml_esc "$server")"
		udp_relay_ipv6 = $(toml_bool "$udp_relay_ipv6")
		zero_rtt_handshake = $(toml_bool "$zero_rtt_handshake")
		dual_stack = $(toml_bool "$dual_stack")
		auth_timeout = "${auth_timeout}s"
		stream_timeout = "${stream_timeout}s"
		gc_interval = "${gc_interval}s"
		gc_lifetime = "${gc_lifetime}s"

		[users]
		$(printf '%b' "$users" | sed 's/^/\t/')

		[tls]
		self_sign = $(toml_bool "$self_sign")
		hostname = "$(toml_esc "$hostname")"
		certificate = "$(toml_esc "$certificate")"
		private_key = "$(toml_esc "$private_key")"
		auto_ssl = $(toml_bool "$auto_ssl")
		acme_email = "$(toml_esc "$acme_email")"
		alpn = ["$(toml_esc "$alpn")"]

		[quic]
		initial_mtu = ${initial_mtu}
		min_mtu = ${min_mtu}
		send_window = ${send_window}
		receive_window = ${receive_window}
		max_idle_time = "${max_idle_time}s"

		[quic.congestion_control]
		controller = "$(toml_esc "$congestion_control")"
	CONF

	# 追加 RESTful API（仅在配置了地址时）
	if [ -n "$restful_addr" ]; then
		cat >> "$CONF_FILE" <<-CONF

			[restful]
			addr = "$(toml_esc "$restful_addr")"
			secret = "$(toml_esc "$restful_secret")"
			maximum_clients_per_user = ${max_clients}
		CONF
	fi
}

case "$1" in
	sync_config) sync_config ;;
esac
