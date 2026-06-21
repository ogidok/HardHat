# Maintainer: HardHat Contributors

pkgname=hardhat
pkgver=1.0.8
pkgrel=1
pkgdesc="Arch Linux Bash CLI for baseline security auditing and guided UFW hardening"
url="https://github.com/hardhat-dev/hardhat"
arch=('x86_64' 'aarch64')
license=('MIT')
depends=('bash')
optdepends=(
  'ufw: firewall backend used by firewall audit/apply'
  'sudo: run privileged actions when not executing as root'
)
source=()
sha256sums=()

package() {
  local _runtime_dir="${pkgdir}/opt/hardhat"
  local _doc_dir="${pkgdir}/usr/share/doc/hardhat"

  install -d "${_runtime_dir}" "${pkgdir}/usr/bin" "${_doc_dir}"

  cp -a "${startdir}/bin" "${_runtime_dir}/"
  cp -a "${startdir}/lib" "${_runtime_dir}/"
  cp -a "${startdir}/modules" "${_runtime_dir}/"
  install -m 0644 "${startdir}/accsi.txt" "${_runtime_dir}/accsi.txt"

  # Ensure CLI entrypoint is executable in package runtime.
  chmod 0755 "${_runtime_dir}/bin/hardhat"

  # Package-managed command path for Arch packages.
  ln -s "/opt/hardhat/bin/hardhat" "${pkgdir}/usr/bin/hardhat"

  install -m 0644 "${startdir}/README.md" "${_doc_dir}/README.md"
  install -m 0644 "${startdir}/LICENSE" "${_doc_dir}/LICENSE"
  install -m 0644 "${startdir}/install.sh" "${_doc_dir}/install.sh"
  install -m 0644 "${startdir}/uninstall.sh" "${_doc_dir}/uninstall.sh"

  if [[ -d "${startdir}/docs" ]]; then
    install -d "${_doc_dir}/docs"
    cp -a "${startdir}/docs/." "${_doc_dir}/docs/"
  fi
}
