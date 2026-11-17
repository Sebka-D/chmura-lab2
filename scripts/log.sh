# Pomocnik: wykonuje polecenie, pokazuje je i zapisuje razem z wynikiem do dowody/polecenia-lstk.txt
export PATH="$PATH:/c/Users/sebas/.local/bin:/c/Program Files/Amazon/AWSCLIV2"
export MSYS_NO_PATHCONV=1
LOG="$(dirname "${BASH_SOURCE[0]}")/../dowody/polecenia-lstk.txt"
run() {
  { echo; echo "\$ $*"; } | tee -a "$LOG"
  eval "$@" 2>&1 | tee -a "$LOG"
}
section() { { echo; echo "######## $* ########"; } | tee -a "$LOG"; }
