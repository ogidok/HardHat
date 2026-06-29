# Maintainer: HardHat Contributors

pkgname=hardhat
pkgver=1.0.8
pkgrel=1
_tag="v${pkgver}"
pkgdesc="Arch Linux Bash CLI for baseline security auditing and guided UFW hardening"
url="https://github.com/ogidok/HardHat"
arch=('x86_64' 'aarch64')
license=('MIT')
depends=('bash')
options=(!debug)
optdepends=(
  'ufw: firewall backend used by firewall audit/apply'
  'sudo: run privileged actions when not executing as root'
)
source=("${pkgname}-${pkgver}.tar.gz::${url}/archive/refs/tags/${_tag}.tar.gz")
sha256sums=('bb9e4af5d81266e2c622dc308b23ce3811f88e48a0a39151cf8dbdc4818698d8')

package() {
  local _src_dir="${srcdir}/HardHat-${_tag}"
  if [[ ! -d "${_src_dir}" ]]; then
    _src_dir="${srcdir}/HardHat-${pkgver}"
  fi
  local _runtime_dir="${pkgdir}/opt/hardhat"
  local _doc_dir="${pkgdir}/usr/share/doc/hardhat"
  local _license_dir="${pkgdir}/usr/share/licenses/hardhat"

  install -d "${_runtime_dir}" "${pkgdir}/usr/bin" "${_doc_dir}" "${_license_dir}"

  cp -a "${_src_dir}/bin" "${_runtime_dir}/"
  cp -a "${_src_dir}/lib" "${_runtime_dir}/"
  cp -a "${_src_dir}/modules" "${_runtime_dir}/"
  install -m 0644 "${_src_dir}/accsi.txt" "${_runtime_dir}/accsi.txt"

  # Ensure CLI entrypoint is executable in package runtime.
  chmod 0755 "${_runtime_dir}/bin/hardhat"

  # Package-managed command path for Arch packages.
  ln -s "/opt/hardhat/bin/hardhat" "${pkgdir}/usr/bin/hardhat"

  install -m 0644 "${_src_dir}/README.md" "${_doc_dir}/README.md"
  install -m 0644 "${_src_dir}/CHANGELOG.md" "${_doc_dir}/CHANGELOG.md"
  install -m 0644 "${_src_dir}/install.sh" "${_doc_dir}/install.sh"
  install -m 0644 "${_src_dir}/uninstall.sh" "${_doc_dir}/uninstall.sh"
  install -m 0644 "${_src_dir}/LICENSE" "${_license_dir}/LICENSE"

  if [[ -d "${_src_dir}/docs" ]]; then
    install -d "${_doc_dir}/docs"
    cp -a "${_src_dir}/docs/." "${_doc_dir}/docs/"
  fi
}
