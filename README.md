
## Installaion

https://xschem.sourceforge.io/stefan/xschem_man/install_xschem.html

https://xschem.sourceforge.io/stefan/xschem_man/tutorial_xschem_sky130.html


## Setup

```bash
export PDK_ROOT=<pdk-dir>
export PDK=sky130A
```

```bash
virtualenv -p python3.12 venv
source venv/bin/activate
pip install ciel
ciel enable 026824c7969ce6f4fc9678e6ca04b0a06a596c4b
```

```bash
mkdir -p ~/.xschem/simulations
cat << EOF > ~/.xschem/simulations/.spiceinit
set ngbehavior=hsa
set ng_nomodcheck
EOF
```

```bash
echo "source $PDK_ROOT/$PDK/libs.tech/xschem/xschemrc" \
> <design-dir>/xschemrc
```

## Workflow

- Go inside `<design-dir>` before calling `xschem`

## Note

- https://tmec.nectec.or.th/lmsX/course/section.php?id=6
- https://github.com/wityam/aicoss

https://github.com/mattvenn/awesome-opensource-asic-resources
https://github.com/iic-jku/iic-osic-tools
https://github.com/bmurmann/Book-on-MOS-stages
