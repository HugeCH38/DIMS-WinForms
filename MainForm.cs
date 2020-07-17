using MaterialSkin;
using MaterialSkin.Controls;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Data.SqlClient;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace DIMS {
    public partial class MainForm : MaterialForm { // 主窗体类 // Inherit from MaterialForm
        private readonly MaterialSkinManager materialSkinManager; // My material skin manager
        private int colorSchemeIndex = 0; // 颜色主题索引
        private int drawerSchemeIndex = 0; // 侧边栏主题索引

        private Staff staff; // 当前登录的药库职员

        private static string connStr = Properties.Settings.Default.DatabaseConnStr; // 数据库连接字符串
        private SqlConnection conn = new SqlConnection(connStr); // 数据库连接

        public MainForm() { // 构造函数
            InitializeComponent();

            // Initialize my material skin manager
            materialSkinManager = MaterialSkinManager.Instance;
            materialSkinManager.AddFormToManage(this);

            // Set this to false to disable backcolor enforcing on non-materialSkin components
            // This HAS to be set before the AddFormToManage()
            materialSkinManager.EnforceBackcolorOnAllComponents = true;

            // Initialize my color scheme, theme, drawer theme
            materialSkinManager.ColorScheme = new ColorScheme(Primary.Indigo500, Primary.Indigo700, Primary.Indigo100, Accent.Pink200, TextShade.WHITE);
            materialSkinManager.Theme = MaterialSkinManager.Themes.LIGHT;
            DrawerShowIconsWhenHidden = true;
            DrawerUseColors = false;
            DrawerHighlightWithAccent = true;
            DrawerBackgroundWithAccent = false;

            // 未登录前隐藏除登陆卡片外的所有卡片
            SetStateNotLoggedIn();
        }

        private void SetStateNotLoggedIn() { // 设置窗体状态为未登录状态
            cardLogin.Visible = true;
            cardHomePage.Visible = false;
            cardIn.Visible = false;
            cardOut.Visible = false;
            cardDestroy.Visible = false;
            cardInDrugs.Visible = false;
            cardOutDrugs.Visible = false;
            cardDestroyedDrugs.Visible = false;
            cardQuery.Visible = false;
        }

        private void SetStateLoggedIn() { // 设置窗体状态为已登录状态
            // ComboBox 控件
            DataTable dtDrugs = getDataTable("SELECT DrugId, DrugName FROM View_InDrugsSummary");
            cboDrugId1.DataSource = dtDrugs;
            cboDrugId1.ValueMember = "DrugId";
            cboDrugId1.DisplayMember = "DrugName";
            cboDrugId1.SelectedIndex = -1;
            cboDrugId1.Text = "药品名称";
            cboDrugId2.DataSource = dtDrugs.Copy(); // 使用副本以避免绑定同一数据源的 ComboBox 控件联动
            cboDrugId2.ValueMember = "DrugId";
            cboDrugId2.DisplayMember = "DrugName";
            cboDrugId2.SelectedIndex = -1;
            cboDrugId2.Text = "药品名称";
            cboDrugId3.DataSource = dtDrugs.Copy(); // 使用副本以避免绑定同一数据源的 ComboBox 控件联动
            cboDrugId3.ValueMember = "DrugId";
            cboDrugId3.DisplayMember = "DrugName";
            cboDrugId3.SelectedIndex = -1;
            cboDrugId3.Text = "药品名称";
            cboDrugId4.DataSource = dtDrugs.Copy(); // 使用副本以避免绑定同一数据源的 ComboBox 控件联动
            cboDrugId4.ValueMember = "DrugId";
            cboDrugId4.DisplayMember = "DrugName";
            cboDrugId4.SelectedIndex = -1;
            cboDrugId4.Text = "药品名称";

            DataTable dtSuppliers = getDataTable("SELECT SupplierId, SupplierName FROM Suppliers");
            cboSupplierId1.DataSource = dtSuppliers;
            cboSupplierId1.ValueMember = "SupplierId";
            cboSupplierId1.DisplayMember = "SupplierName";
            cboSupplierId1.SelectedIndex = -1;
            cboSupplierId1.Text = "供应商名称";
            cboSupplierId3.DataSource = dtSuppliers.Copy(); // 使用副本以避免绑定同一数据源的 ComboBox 控件联动
            cboSupplierId3.ValueMember = "SupplierId";
            cboSupplierId3.DisplayMember = "SupplierName";
            cboSupplierId3.SelectedIndex = -1;
            cboSupplierId3.Text = "供应商名称";
            cboSupplierId4.DataSource = dtSuppliers.Copy(); // 使用副本以避免绑定同一数据源的 ComboBox 控件联动
            cboSupplierId4.ValueMember = "SupplierId";
            cboSupplierId4.DisplayMember = "SupplierName";
            cboSupplierId4.SelectedIndex = -1;
            cboSupplierId4.Text = "供应商名称";

            DataTable dtNonStaffsInWarehouse = getDataTable("SELECT StaffId, FullTitle FROM View_NonStaffsInWarehouseDetails ORDER BY StaffNo");
            cboStaffId_Handover2.DataSource = dtNonStaffsInWarehouse;
            cboStaffId_Handover2.ValueMember = "StaffId";
            cboStaffId_Handover2.DisplayMember = "FullTitle";
            cboStaffId_Handover2.SelectedIndex = -1;
            cboStaffId_Handover2.Text = "交接部门及交接职员";

            DataTable dtStaffsInWarehouse = getDataTable("SELECT StaffId, FullTitle FROM View_StaffsInWarehouseDetails ORDER BY StaffNo");
            cboStaffId_In3.DataSource = dtStaffsInWarehouse;
            cboStaffId_In3.ValueMember = "StaffId";
            cboStaffId_In3.DisplayMember = "FullTitle";
            cboStaffId_In3.SelectedIndex = -1;
            cboStaffId_In3.Text = "入库职员";
            cboStaffId4.DataSource = dtStaffsInWarehouse.Copy(); // 使用副本以避免绑定同一数据源的 ComboBox 控件联动
            cboStaffId4.ValueMember = "StaffId";
            cboStaffId4.DisplayMember = "FullTitle";
            cboStaffId4.SelectedIndex = -1;
            cboStaffId4.Text = "负责职员";

            DataTable dtNonWarehouseDepartments = getDataTable("SELECT DISTINCT DepartmentId, DepartmentName FROM View_NonStaffsInWarehouseDetails");
            cboDepartment_Handover4.DataSource = dtNonWarehouseDepartments;
            cboDepartment_Handover4.ValueMember = "DepartmentId";
            cboDepartment_Handover4.DisplayMember = "DepartmentName";
            cboDepartment_Handover4.SelectedIndex = -1;
            cboDepartment_Handover4.Text = "交接部门";

            // DateTimePicker 控件 (重要！)
            dtpDrugBatch1.Value = DateTime.Parse(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")); // 只需要精确到秒
            dtpDrugInTime1.Value = DateTime.Parse(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")); // 只需要精确到秒
            dtpDrugOutTime2.Value = DateTime.Parse(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")); // 只需要精确到秒
            dtpDrugBatch3.Value = DateTime.Parse(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")); // 只需要精确到秒
            dtpDrugInTime3.Value = DateTime.Parse(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")); // 只需要精确到秒
            dtpDrugDestroyTime3.Value = DateTime.Parse(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")); // 只需要精确到秒

            // MaterialCard 控件
            cardLogin.Visible = false;
            cardHomePage.Visible = true;
            cardIn.Visible = true;
            cardOut.Visible = true;
            cardDestroy.Visible = true;
            cardInDrugs.Visible = true;
            cardOutDrugs.Visible = true;
            cardDestroyedDrugs.Visible = true;
            cardQuery.Visible = true;

            // Switch 控件
            switchSummary.Checked = false;

            // Checkbox 控件：初始“记录类别”为“库存药品批次记录”
            chkInDrugsDetails.Checked = true;
            chkInDrugsSummary.Checked = false;
            chkOutDrugs.Checked = false;
            chkDestroyedDrugs.Checked = false;

            // RadioButton 控件：初始“时间范围”为“不限”
            rdoAnyTime.Checked = true;
            rdo30Days.Checked = false;
            rdo90Days.Checked = false;
            rdo180Days.Checked = false;
            rdo360Days.Checked = false;

            // DataGridView 控件
            dgvClose2Expiry.BackgroundColor = System.Drawing.Color.White;
            dgvLowInventory.BackgroundColor = System.Drawing.Color.White;
            dgvInDrugs.BackgroundColor = System.Drawing.Color.White;
            dgvOutDrugs.BackgroundColor = System.Drawing.Color.White;
            dgvDestroyedDrugs.BackgroundColor = System.Drawing.Color.White;
            bindData();
            dgvQuery.DataSource = null;
        }

        private void switchSummary_CheckedChanged(object sender, EventArgs e) { // 切换查看库存药品的视图 (细节视图/汇总视图)
            if (switchSummary.Checked == false) {
                dgvInDrugs.DataSource = getDataTable("SELECT DrugName AS 药品名称, DrugBatch AS 批次, SupplierName AS 供应商, StaffName_In AS 入库职员, DrugInTime AS 入库时间, DrugNum AS 数量, RemainingLife AS '剩余保质期 (天数)' FROM View_InDrugsDetails ORDER BY DrugInTime DESC");
                dgvInDrugs.Columns["批次"].DefaultCellStyle.Format = "yyyy-MM-dd HH:mm:ss"; // 否则不显示秒
                dgvInDrugs.Columns["入库时间"].DefaultCellStyle.Format = "yyyy-MM-dd HH:mm:ss"; // 否则不显示秒
            }
            else {
                dgvInDrugs.DataSource = getDataTable("SELECT DrugName AS 药品名称, DrugNum AS 库存总数 FROM View_InDrugsSummary ORDER BY DrugNum ASC");
            }
        }

        private void bindData() { // 绑定各个 DataGridView 控件的数据源
            dgvClose2Expiry.DataSource = getDataTable("SELECT DrugName AS 药品名称, DrugBatch AS 批次, SupplierName AS 供应商, StaffName_In AS 入库职员, DrugInTime AS 入库时间, DrugNum AS 数量, RemainingLife AS '剩余保质期 (天数)' FROM View_InDrugsDetails_Close2Expiry ORDER BY RemainingLife ASC");
            dgvClose2Expiry.Columns["批次"].DefaultCellStyle.Format = "yyyy-MM-dd HH:mm:ss"; // 否则不显示秒
            dgvClose2Expiry.Columns["入库时间"].DefaultCellStyle.Format = "yyyy-MM-dd HH:mm:ss"; // 否则不显示秒

            dgvLowInventory.DataSource = getDataTable("SELECT DrugName AS 药品名称, DrugNum AS 库存总数 FROM View_InDrugsSummary_LowInventory ORDER BY DrugNum ASC");

            if (switchSummary.Checked == false) {
                dgvInDrugs.DataSource = getDataTable("SELECT DrugName AS 药品名称, DrugBatch AS 批次, SupplierName AS 供应商, StaffName_In AS 入库职员, DrugInTime AS 入库时间, DrugNum AS 数量, RemainingLife AS '剩余保质期 (天数)' FROM View_InDrugsDetails ORDER BY DrugInTime DESC");
                dgvInDrugs.Columns["批次"].DefaultCellStyle.Format = "yyyy-MM-dd HH:mm:ss"; // 否则不显示秒
                dgvInDrugs.Columns["入库时间"].DefaultCellStyle.Format = "yyyy-MM-dd HH:mm:ss"; // 否则不显示秒
            }
            else {
                dgvInDrugs.DataSource = getDataTable("SELECT DrugName AS 药品名称, DrugNum AS 库存总数 FROM View_InDrugsSummary ORDER BY DrugNum ASC");
            }

            dgvOutDrugs.DataSource = getDataTable("SELECT DrugName AS 药品名称, DrugBatch AS 批次, SupplierName AS 供应商, StaffName_In AS 入库职员, DrugInTIme AS 入库时间, StaffName_Out AS 出库职员, DrugOutTime AS 出库时间, DepartmentName_Handover AS 交接部门, StaffName_Handover AS 交接人员, DrugNum AS 数量 FROM View_OutDrugsDetails ORDER BY DrugOutTime DESC");
            dgvOutDrugs.Columns["批次"].DefaultCellStyle.Format = "yyyy-MM-dd HH:mm:ss"; // 否则不显示秒
            dgvOutDrugs.Columns["入库时间"].DefaultCellStyle.Format = "yyyy-MM-dd HH:mm:ss"; // 否则不显示秒
            dgvOutDrugs.Columns["出库时间"].DefaultCellStyle.Format = "yyyy-MM-dd HH:mm:ss"; // 否则不显示秒

            dgvDestroyedDrugs.DataSource = getDataTable("SELECT DrugName AS 药品名称, DrugBatch AS 批次, SupplierName AS 供应商, StaffName_In AS 入库职员, DrugInTime AS 入库时间, StaffName_Destroy AS 销毁职员, DrugDestroyTime AS 销毁时间, DrugNum AS 数量 FROM View_DestroyedDrugsDetails ORDER BY DrugDestroyTime DESC");
            dgvDestroyedDrugs.Columns["批次"].DefaultCellStyle.Format = "yyyy-MM-dd HH:mm:ss"; // 否则不显示秒
            dgvDestroyedDrugs.Columns["入库时间"].DefaultCellStyle.Format = "yyyy-MM-dd HH:mm:ss"; // 否则不显示秒
            dgvDestroyedDrugs.Columns["销毁时间"].DefaultCellStyle.Format = "yyyy-MM-dd HH:mm:ss"; // 否则不显示秒
        }

        private DataTable getDataTable(string sql) { // 以 DataTable 的形式返回数据库中的数据
            using (SqlConnection conn = new SqlConnection(connStr)) {
                SqlDataAdapter da = new SqlDataAdapter(sql, conn);
                DataTable dt = new DataTable();
                da.Fill(dt);
                return dt;
            }
        }

        private void btnChangeColorTheme_Click(object sender, EventArgs e) { // 更改颜色主题
            colorSchemeIndex = ++colorSchemeIndex % 4;
            updateColor();
        }

        private void updateColor() { // 根据颜色主题索引更改颜色主题
            // color schemes
            switch (colorSchemeIndex) {
                case 0:
                    materialSkinManager.ColorScheme = new ColorScheme(Primary.Indigo500, Primary.Indigo700, Primary.Indigo100, Accent.Pink200, TextShade.WHITE);
                    break;
                case 1:
                    materialSkinManager.ColorScheme = new ColorScheme(Primary.Teal500, Primary.Teal700, Primary.Teal200, Accent.Pink200, TextShade.WHITE);
                    break;
                case 2:
                    materialSkinManager.ColorScheme = new ColorScheme(Primary.Green600, Primary.Green700, Primary.Green200, Accent.Red100, TextShade.WHITE);
                    break;
                case 3:
                    materialSkinManager.ColorScheme = new ColorScheme(Primary.BlueGrey800, Primary.BlueGrey900, Primary.BlueGrey500, Accent.LightBlue200, TextShade.WHITE);
                    break;
            }
            Invalidate();
        }

        private void btnChangeDrawerTheme_Click(object sender, EventArgs e) { // 更改侧边栏主题
            drawerSchemeIndex = ++drawerSchemeIndex % 4;
            updateDrawer();
        }

        private void updateDrawer() { // 根据侧边栏主题索引更改侧边栏主题
            // drawer schemes
            switch (drawerSchemeIndex) {
                case 0:
                    DrawerHighlightWithAccent = true;
                    DrawerBackgroundWithAccent = false;
                    break;
                case 1:
                    DrawerHighlightWithAccent = false;
                    DrawerBackgroundWithAccent = true;
                    break;
                case 2:
                    DrawerHighlightWithAccent = false;
                    DrawerBackgroundWithAccent = false;
                    break;
                case 3:
                    DrawerHighlightWithAccent = true;
                    DrawerBackgroundWithAccent = true;
                    break;
            }
            Invalidate();
        }

        private void txtNo_KeyDown(object sender, KeyEventArgs e) { // 监听输入编号时的键盘 (按下回车时跳到登陆密码 TextBox)
            if (e.KeyCode == Keys.Enter) {
                SendKeys.Send("{Tab}");
            }
        }

        private void txtPwd_KeyDown(object sender, KeyEventArgs e) { // 监听输入登录密码时的键盘 (按下回车时触发提交按钮)
            if (e.KeyCode == Keys.Enter) {
                btnLogin_Click(sender, e);
            }
        }

        private void btnReset0_Click(object sender, EventArgs e) { // 点击重置按钮时，重置登录表单
            txtNo.Text = "";
            txtPwd.Text = "";
        }

        private void btnLogin_Click(object sender, EventArgs e) { // 点击登入按钮时，尝试登录操作
            if (txtNo.Text == "") {
                MessageBox.Show("编号不可为空！", "请检查输入！");
                return;
            }
            if (txtPwd.Text == "") {
                MessageBox.Show("登陆密码不可为空！", "请检查输入！");
                return;
            }
            Staff tempStaff = new Staff(txtNo.Text.Trim(), txtPwd.Text.Trim());
            if (tempStaff.GetInfo()) {
                if (tempStaff.Dept.Name == "药库") {
                    staff = tempStaff;
                    SetStateLoggedIn();
                    btnWelcome.Text = "欢迎，" + staff.Name + "！";
                }
                else {
                    MessageBox.Show("非药库部门职员无权使用！", "请更换账号登陆！");
                }
            }
            else {
                MessageBox.Show("编号不存在或登陆密码错误！", "请检查输入！");
            }
        }

        private void btnLogout_Click(object sender, EventArgs e) { // 点击注销按钮时，尝试注销操作
            staff = null;
            SetStateNotLoggedIn();
        }

        private void dgvClose2Expiry_CellMouseDown(object sender, DataGridViewCellMouseEventArgs e) { // 设置临期库存药品批次列表右键菜单的显示
            if (e.RowIndex != -1 && e.Button == System.Windows.Forms.MouseButtons.Right) {
                dgvClose2Expiry.ClearSelection();
                dgvClose2Expiry.Rows[e.RowIndex].Selected = true;
                cmsInDrugs.Show(MousePosition.X, MousePosition.Y);
            }
        }

        private void tspMenuItem1_Click(object sender, EventArgs e) { // 设置临期库存药品批次列表右键菜单的操作
            SqlCommand cmd = new SqlCommand();
            cmd.CommandText = "SELECT DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime FROM View_InDrugsDetails WHERE DrugName=@DrugName AND DrugBatch=@DrugBatch AND SupplierName=@SupplierName AND StaffName_In=@StaffName_In AND DrugInTime=@DrugInTime";
            cmd.Connection = conn;
            DataGridViewRow dgvr = dgvClose2Expiry.Rows[dgvClose2Expiry.SelectedRows[0].Index];
            SqlParameter[] parms = new SqlParameter[5];
            parms[0] = new SqlParameter("@DrugName", SqlDbType.NVarChar, 32);
            parms[0].Value = dgvr.Cells["药品名称"].Value.ToString();
            parms[1] = new SqlParameter("@DrugBatch", SqlDbType.DateTime);
            parms[1].Value = Convert.ToDateTime(dgvr.Cells["批次"].Value.ToString());
            parms[2] = new SqlParameter("@SupplierName", SqlDbType.NVarChar, 32);
            parms[2].Value = dgvr.Cells["供应商"].Value.ToString();
            parms[3] = new SqlParameter("@StaffName_In", SqlDbType.NVarChar, 32);
            parms[3].Value = dgvr.Cells["入库职员"].Value.ToString();
            parms[4] = new SqlParameter("@DrugInTime", SqlDbType.DateTime);
            parms[4].Value = Convert.ToDateTime(dgvr.Cells["入库时间"].Value.ToString());
            foreach (SqlParameter parm in parms) {
                cmd.Parameters.Add(parm);
            }
            SqlDataReader dr = null;
            try {
                conn.Open();
                dr = cmd.ExecuteReader();
                if (dr.Read()) {
                    cboDrugId3.SelectedValue = dr["DrugId"];
                    cboSupplierId3.SelectedValue = dr["SupplierId"];
                    dtpDrugBatch3.Value = Convert.ToDateTime(dr["DrugBatch"].ToString());
                    cboStaffId_In3.SelectedValue = dr["StaffId_In"];
                    dtpDrugInTime3.Value = Convert.ToDateTime(dr["DrugInTime"].ToString());
                    dtpDrugDestroyTime3.Value = DateTime.Parse(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")); // 只需要精确到秒
                    tab.SelectedIndex = 3;
                }
                else {
                    throw new Exception("未知异常！");
                }
            }
            catch (Exception ex) {
                MessageBox.Show("出现异常：" + ex.Message, "请稍后重试！");
            }
            finally {
                if (dr != null && dr.IsClosed == false) {
                    dr.Close();
                }
                if (conn.State == ConnectionState.Open) {
                    conn.Close();
                }
            }
        }

        private void dgvLowInventory_CellMouseDown(object sender, DataGridViewCellMouseEventArgs e) { // 设置低库存量药品列表右键菜单的显示
            if (e.RowIndex != -1 && e.Button == System.Windows.Forms.MouseButtons.Right) {
                dgvLowInventory.ClearSelection();
                dgvLowInventory.Rows[e.RowIndex].Selected = true;
                cmsDrugs.Show(MousePosition.X, MousePosition.Y);
            }
        }

        private void tspMenuItem2_Click(object sender, EventArgs e) { // 设置低库存量药品列表右键菜单的操作
            SqlCommand cmd = new SqlCommand();
            cmd.CommandText = "SELECT DrugId FROM View_InDrugsSummary WHERE DrugName=@DrugName";
            cmd.Connection = conn;
            DataGridViewRow dgvr = dgvLowInventory.Rows[dgvLowInventory.SelectedRows[0].Index];
            SqlParameter parm = new SqlParameter("@DrugName", SqlDbType.NVarChar, 32);
            parm.Value = dgvr.Cells["药品名称"].Value.ToString();
            cmd.Parameters.Add(parm);
            try {
                conn.Open();
                cboDrugId1.SelectedValue = cmd.ExecuteScalar();
                dtpDrugBatch1.Value = DateTime.Parse(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")); // 只需要精确到秒
                dtpDrugInTime1.Value = DateTime.Parse(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")); // 只需要精确到秒
                tab.SelectedIndex = 1;
            }
            catch (Exception ex) {
                MessageBox.Show("出现异常：" + ex.Message, "请稍后重试！");
            }
            finally {
                if (conn.State == ConnectionState.Open) {
                    conn.Close();
                }
            }
        }

        private void btnDecrease1_Click(object sender, EventArgs e) { // 点击减少按钮时，减少药品数量 (同时修改 TextBox 和 ProgressBar 的值)
            prgDrugNum1.Value = prgDrugNum1.Value < 101 ? 1 : (prgDrugNum1.Value - 100);
            txtDrugNum1.Text = prgDrugNum1.Value.ToString();
        }

        private void btnIncrease1_Click(object sender, EventArgs e) { // 点击增加按钮时，增加药品数量 (同时修改 TextBox 和 ProgressBar 的值)
            prgDrugNum1.Value = prgDrugNum1.Value > 9900 ? 10000 : (prgDrugNum1.Value + 100);
            txtDrugNum1.Text = prgDrugNum1.Value.ToString();
        }

        private void txtDrugNum1_Leave(object sender, EventArgs e) { // 焦点离开药品数量 TextBox 时，处理其 Text 值，使其合法
            int tempNum;
            int.TryParse(txtDrugNum1.Text, out tempNum);
            prgDrugNum1.Value = tempNum < 1 ? 1 : (tempNum > 10000 ? 10000 : tempNum);
            txtDrugNum1.Text = prgDrugNum1.Value.ToString();
        }

        private void btnReset1_Click(object sender, EventArgs e) { // 点击重置按钮时，重置药品入库表单
            cboDrugId1.SelectedIndex = -1;
            cboDrugId1.Text = "药品名称";
            cboSupplierId1.SelectedIndex = -1;
            cboSupplierId1.Text = "供应商名称";
            dtpDrugBatch1.Value = DateTime.Parse(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")); // 只需要精确到秒
            dtpDrugInTime1.Value = DateTime.Parse(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")); // 只需要精确到秒
            prgDrugNum1.Value = 100;
            txtDrugNum1.Text = prgDrugNum1.Value.ToString();
        }

        private void btnSubbmit1_Click(object sender, EventArgs e) { // 点击提交按钮时，尝试入库操作
            if (cboDrugId1.SelectedIndex == -1) {
                MessageBox.Show("药品名称不可为空！", "请检查输入！");
                return;
            }
            if (cboSupplierId1.SelectedIndex == -1) {
                MessageBox.Show("供应商名称不可为空！", "请检查输入！");
                return;
            }
            if (DateTime.Compare(dtpDrugBatch1.Value, DateTime.Parse(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"))) == 1) { // 只需要精确到秒
                MessageBox.Show("药品生产时间不可能早于当前时间！", "请检查输入！");
                return;
            }
            if (DateTime.Compare(dtpDrugInTime1.Value, DateTime.Parse(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"))) == 1) { // 只需要精确到秒
                MessageBox.Show("药品入库时间不可能早于当前时间！", "请检查输入！");
                return;
            }
            if (DateTime.Compare(dtpDrugBatch1.Value, dtpDrugInTime1.Value) == 1) {
                MessageBox.Show("药品入库时间不可能早于药品生产时间！", "请检查输入！");
                return;
            }
            SqlCommand cmd = new SqlCommand();
            cmd.Connection = conn;
            SqlParameter[] parms = new SqlParameter[6];
            parms[0] = new SqlParameter("@DrugId", SqlDbType.UniqueIdentifier);
            parms[0].Value = cboDrugId1.SelectedValue;
            parms[1] = new SqlParameter("@DrugBatch", SqlDbType.DateTime);
            parms[1].Value = dtpDrugBatch1.Value;
            parms[2] = new SqlParameter("@SupplierId", SqlDbType.UniqueIdentifier);
            parms[2].Value = cboSupplierId1.SelectedValue;
            parms[3] = new SqlParameter("@StaffId_In", SqlDbType.UniqueIdentifier);
            parms[3].Value = staff.Id;
            parms[4] = new SqlParameter("@DrugInTime", SqlDbType.DateTime);
            parms[4].Value = dtpDrugInTime1.Value;
            parms[5] = new SqlParameter("@DrugNum", SqlDbType.SmallInt);
            parms[5].Value = prgDrugNum1.Value;
            foreach (SqlParameter parm in parms) {
                cmd.Parameters.Add(parm);
            }
            SqlDataReader dr = null;
            try {
                conn.Open();
                cmd.CommandText = "SELECT * FROM InDrugs WHERE DrugId=@DrugId AND DrugBatch=@DrugBatch AND SupplierId=@SupplierId AND StaffId_In=@StaffId_In AND DrugInTime=@DrugInTime";
                dr = cmd.ExecuteReader();
                if (dr.Read()) {
                    throw new MyException("该记录已存在！");
                }
                dr.Close();
                cmd.CommandText = "INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum) VALUES(@DrugId, @DrugBatch, @SupplierId, @StaffId_In, @DrugInTime, @DrugNum)";
                int affectedRowsNum = cmd.ExecuteNonQuery();
                if (affectedRowsNum != 1) {
                    throw new Exception("未知异常！");
                }
                bindData(); // 重新绑定数据以保证数据一致性
                btnQuery_Click(sender, e);
                MessageBox.Show("登记成功！");
            }
            catch (MyException ex) {
                MessageBox.Show(ex.Message, "请检查输入！");
            }
            catch (Exception ex) {
                MessageBox.Show("出现异常：" + ex.Message, "请稍后重试！");
            }
            finally {
                if (dr != null && dr.IsClosed == false) {
                    dr.Close();
                }
                if (conn.State == ConnectionState.Open) {
                    conn.Close();
                }
            }
        }

        private void btnDecrease2_Click(object sender, EventArgs e) { // 点击减少按钮时，减少药品数量 (同时修改 TextBox 和 ProgressBar 的值)
            prgDrugNum2.Value = prgDrugNum2.Value < 101 ? 1 : (prgDrugNum2.Value - 100);
            txtDrugNum2.Text = prgDrugNum2.Value.ToString();
        }

        private void btnIncrease2_Click(object sender, EventArgs e) { // 点击增加按钮时，增加药品数量 (同时修改 TextBox 和 ProgressBar 的值)
            prgDrugNum2.Value = prgDrugNum2.Value > 9900 ? 10000 : (prgDrugNum2.Value + 100);
            txtDrugNum2.Text = prgDrugNum2.Value.ToString();
        }

        private void txtDrugNum2_Leave(object sender, EventArgs e) { // 焦点离开药品数量 TextBox 时，处理其 Text 值，使其合法
            int tempNum;
            int.TryParse(txtDrugNum2.Text, out tempNum);
            prgDrugNum2.Value = tempNum < 1 ? 1 : (tempNum > 10000 ? 10000 : tempNum);
            txtDrugNum2.Text = prgDrugNum2.Value.ToString();
        }

        private void btnReset2_Click(object sender, EventArgs e) { // 点击重置按钮时，重置药品出库表单
            cboDrugId2.SelectedIndex = -1;
            cboDrugId2.Text = "药品名称";
            cboStaffId_Handover2.SelectedIndex = -1;
            cboStaffId_Handover2.Text = "交接部门及交接职员";
            prgDrugNum2.Value = 100;
            txtDrugNum2.Text = prgDrugNum2.Value.ToString();
            dtpDrugOutTime2.Value = DateTime.Parse(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")); // 只需要精确到秒
        }

        private void btnSubmit2_Click(object sender, EventArgs e) { // 点击提交按钮时，尝试出库操作
            if (cboDrugId2.SelectedIndex == -1) {
                MessageBox.Show("药品名称不可为空！", "请检查输入！");
                return;
            }
            if (cboStaffId_Handover2.SelectedIndex == -1) {
                MessageBox.Show("交接部门及交接职员不可为空！", "请检查输入！");
                return;
            }
            if (DateTime.Compare(dtpDrugOutTime2.Value, DateTime.Parse(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"))) == 1) { // 只需要精确到秒
                MessageBox.Show("药品出库时间不可能早于当前时间！", "请检查输入！");
                return;
            }
            SqlCommand cmd = new SqlCommand();
            cmd.Connection = conn;
            SqlParameter[] parms = new SqlParameter[6];
            parms[0] = new SqlParameter("@DrugId", SqlDbType.UniqueIdentifier);
            parms[0].Value = cboDrugId2.SelectedValue;
            parms[1] = new SqlParameter("@DrugNumSum", SqlDbType.Int);
            parms[1].Value = prgDrugNum2.Value;
            parms[2] = new SqlParameter("@StaffId_Out", SqlDbType.UniqueIdentifier);
            parms[2].Value = staff.Id;
            parms[3] = new SqlParameter("@DrugOutTime", SqlDbType.DateTime);
            parms[3].Value = dtpDrugOutTime2.Value;
            parms[4] = new SqlParameter("@Staffid_Handover", SqlDbType.UniqueIdentifier);
            parms[4].Value = cboStaffId_Handover2.SelectedValue;
            parms[5] = new SqlParameter("@returnValue", SqlDbType.SmallInt);
            parms[5].Direction = ParameterDirection.Output;
            foreach (SqlParameter parm in parms) {
                cmd.Parameters.Add(parm);
            }
            try {
                conn.Open();
                cmd.CommandText = "SELECT DrugNum FROM View_InDrugsSummary WHERE DrugId=@DrugId";
                int inNum;
                int.TryParse(cmd.ExecuteScalar().ToString(), out inNum);
                if (inNum < prgDrugNum2.Value) {
                    throw new MyException("库存量不足！");
                }
                cmd.CommandText = "sp_OutInDrugs";
                cmd.CommandType = CommandType.StoredProcedure;
                int affectedRowsNum = cmd.ExecuteNonQuery();
                if (affectedRowsNum == 0) {
                    throw new Exception("未知异常！");
                }
                bindData(); // 重新绑定数据以保证数据一致性
                btnQuery_Click(sender, e);
                MessageBox.Show("登记成功！");
            }
            catch (MyException ex) {
                MessageBox.Show(ex.Message, "请检查输入！");
            }
            catch (Exception ex) {
                MessageBox.Show("出现异常：" + ex.Message, "请稍后重试！");
            }
            finally {
                if (conn.State == ConnectionState.Open) {
                    conn.Close();
                }
            }
        }

        private void btnReset3_Click(object sender, EventArgs e) { // 点击重置按钮时，重置药品销毁表单
            cboDrugId3.SelectedIndex = -1;
            cboDrugId3.Text = "药品名称";
            cboSupplierId3.SelectedIndex = -1;
            cboSupplierId3.Text = "供应商名称";
            dtpDrugBatch3.Value = DateTime.Parse(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")); // 只需要精确到秒
            cboStaffId_In3.SelectedIndex = -1;
            cboStaffId_In3.Text = "入库职员";
            dtpDrugInTime3.Value = DateTime.Parse(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")); // 只需要精确到秒
            dtpDrugDestroyTime3.Value = DateTime.Parse(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")); // 只需要精确到秒
        }

        private void btnSubmit3_Click(object sender, EventArgs e) { // 点击提交按钮时，尝试销毁操作
            if (cboDrugId3.SelectedIndex == -1) {
                MessageBox.Show("药品名称不可为空！", "请检查输入！");
                return;
            }
            if (cboSupplierId3.SelectedIndex == -1) {
                MessageBox.Show("供应商名称不可为空！", "请检查输入！");
                return;
            }
            if (cboStaffId_In3.SelectedIndex == -1) {
                MessageBox.Show("药品入库职员不可为空！", "请检查输入！");
                return;
            }
            if (DateTime.Compare(dtpDrugBatch3.Value, DateTime.Parse(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"))) == 1) { // 只需要精确到秒
                MessageBox.Show("药品生产时间不可能早于当前时间！", "请检查输入！");
                return;
            }
            if (DateTime.Compare(dtpDrugInTime3.Value, DateTime.Parse(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"))) == 1) { // 只需要精确到秒
                MessageBox.Show("药品入库时间不可能早于当前时间！", "请检查输入！");
                return;
            }
            if (DateTime.Compare(dtpDrugDestroyTime3.Value, DateTime.Parse(DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"))) == 1) { // 只需要精确到秒
                MessageBox.Show("药品销毁时间不可能早于当前时间！", "请检查输入！");
                return;
            }
            if (DateTime.Compare(dtpDrugBatch3.Value, dtpDrugInTime3.Value) == 1) {
                MessageBox.Show("药品入库时间不可能早于药品生产时间！", "请检查输入！");
                return;
            }
            if (DateTime.Compare(dtpDrugInTime3.Value, dtpDrugDestroyTime3.Value) == 1) {
                MessageBox.Show("药品销毁时间不可能早于药品入库时间！", "请检查输入！");
                return;
            }
            SqlCommand cmd = new SqlCommand();
            cmd.Connection = conn;
            SqlParameter[] parms = new SqlParameter[8];
            parms[0] = new SqlParameter("@DrugId", SqlDbType.UniqueIdentifier);
            parms[0].Value = cboDrugId3.SelectedValue;
            parms[1] = new SqlParameter("@DrugBatch", SqlDbType.DateTime);
            parms[1].Value = dtpDrugBatch3.Value;
            parms[2] = new SqlParameter("@SupplierId", SqlDbType.UniqueIdentifier);
            parms[2].Value = cboSupplierId3.SelectedValue;
            parms[3] = new SqlParameter("@StaffId_In", SqlDbType.UniqueIdentifier);
            parms[3].Value = cboStaffId_In3.SelectedValue;
            parms[4] = new SqlParameter("@DrugInTime", SqlDbType.DateTime);
            parms[4].Value = dtpDrugInTime3.Value;
            parms[5] = new SqlParameter("@StaffId_Destroy", SqlDbType.UniqueIdentifier);
            parms[5].Value = staff.Id;
            parms[6] = new SqlParameter("@DrugDestroyTime", SqlDbType.DateTime);
            parms[6].Value = dtpDrugDestroyTime3.Value;
            parms[7] = new SqlParameter("@returnValue", SqlDbType.SmallInt);
            parms[7].Direction = ParameterDirection.Output;
            foreach (SqlParameter parm in parms) {
                cmd.Parameters.Add(parm);
            }
            try {
                conn.Open();
                cmd.CommandText = "SELECT COUNT(*) FROM InDrugs WHERE DrugId=@DrugId AND DrugBatch=@DrugBatch AND SupplierId=@SupplierId AND StaffId_In=@StaffId_In AND DrugInTime=@DrugInTime";
                int recordsNum;
                int.TryParse(cmd.ExecuteScalar().ToString(), out recordsNum);
                if (recordsNum == 0) {
                    throw new MyException("不存在该批次药品的记录！");
                }
                cmd.CommandText = "sp_DestroyInDrugs";
                cmd.CommandType = CommandType.StoredProcedure;
                int affectedRowsNum = cmd.ExecuteNonQuery();
                if (affectedRowsNum == 0) {
                    throw new Exception("未知异常！");
                }
                bindData(); // 重新绑定数据以保证数据一致性
                btnQuery_Click(sender, e);
                MessageBox.Show("登记成功！");
            }
            catch (MyException ex) {
                MessageBox.Show(ex.Message, "请检查输入！");
            }
            catch (Exception ex) {
                MessageBox.Show("出现异常：" + ex.Message, "请稍后重试！");
            }
            finally {
                if (conn.State == ConnectionState.Open) {
                    conn.Close();
                }
            }
        }

        private void chk_CheckedChanged(object sender, EventArgs e) { // 处理高级查询中记录类别的冲突 1
            if (chkInDrugsDetails.Checked || chkOutDrugs.Checked || chkDestroyedDrugs.Checked) { // 当“记录类别”为“库存药品批次记录”或“已出库药品批次记录”或“已销毁药品批次记录”时
                // 不可同时查询“库存药品汇总”
                chkInDrugsSummary.Checked = false;
                chkInDrugsSummary.Enabled = false;
            }
            else {
                chkInDrugsSummary.Enabled = true;
            }
        }

        private void chkInDrugsSummary_CheckedChanged(object sender, EventArgs e) { // 处理高级查询中记录类别的冲突 2
            if (chkInDrugsSummary.Checked) { // 当“记录类别”为“库存药品汇总”时
                // 不可同时查询其它类别的记录
                chkInDrugsDetails.Checked = false;
                chkInDrugsDetails.Enabled = false;
                chkOutDrugs.Checked = false;
                chkOutDrugs.Enabled = false;
                chkDestroyedDrugs.Checked = false;
                chkDestroyedDrugs.Enabled = false;
                // 查询条件中仅能包含“药品名称”
                cboSupplierId4.SelectedIndex = -1;
                cboSupplierId4.Text = "供应商名称";
                cboSupplierId4.Enabled = false;
                cboStaffId4.SelectedIndex = -1;
                cboStaffId4.Text = "负责职员";
                cboStaffId4.Enabled = false;
                cboDepartment_Handover4.SelectedIndex = -1;
                cboDepartment_Handover4.Text = "交接部门";
                cboDepartment_Handover4.Enabled = false;
                rdoAnyTime.Checked = false;
                rdoAnyTime.Enabled = false;
                rdo30Days.Checked = false;
                rdo30Days.Enabled = false;
                rdo90Days.Checked = false;
                rdo90Days.Enabled = false;
                rdo180Days.Checked = false;
                rdo180Days.Enabled = false;
                rdo360Days.Checked = false;
                rdo360Days.Enabled = false;
            }
            else {
                chkInDrugsDetails.Enabled = true;
                chkOutDrugs.Enabled = true;
                chkDestroyedDrugs.Enabled = true;
                cboSupplierId4.Enabled = true;
                cboStaffId4.Enabled = true;
                cboDepartment_Handover4.Enabled = true;
                rdoAnyTime.Enabled = true;
                rdo30Days.Enabled = true;
                rdo90Days.Enabled = true;
                rdo180Days.Enabled = true;
                rdo360Days.Enabled = true;
            }
        }

        private void cboDepartment_Handover4_SelectedIndexChanged(object sender, EventArgs e) { // 处理高级查询中查询条件的冲突
            if (cboDepartment_Handover4.SelectedIndex != -1) { // 当查询条件中包含“交接部门”时
                // 仅能查询“已出库药品批次记录”
                chkInDrugsDetails.Checked = false;
                chkInDrugsSummary.Checked = false;
                chkDestroyedDrugs.Checked = false;
                chkInDrugsDetails.Enabled = false;
                chkInDrugsSummary.Enabled = false;
                chkDestroyedDrugs.Enabled = false;
            }
            else {
                chkInDrugsDetails.Enabled = true;
                chkInDrugsSummary.Enabled = true;
                chkDestroyedDrugs.Enabled = true;
            }
        }

        private void btnReset4_Click(object sender, EventArgs e) { // 点击重置按钮时，重置高级查询筛选条件
            // 初始“记录类别”为“库存药品批次记录”
            chkInDrugsDetails.Checked = true;
            chkInDrugsSummary.Checked = false;
            chkOutDrugs.Checked = false;
            chkDestroyedDrugs.Checked = false;
            // ComboBox 控件清空选择，显示 Hint 提示
            cboDrugId4.SelectedIndex = -1;
            cboDrugId4.Text = "药品名称";
            cboSupplierId4.SelectedIndex = -1;
            cboSupplierId4.Text = "供应商名称";
            cboStaffId4.SelectedIndex = -1;
            cboStaffId4.Text = "负责职员";
            cboDepartment_Handover4.SelectedIndex = -1;
            cboDepartment_Handover4.Text = "交接部门";
            // 初始“时间范围”为“不限”
            rdoAnyTime.Checked = true;
            rdo30Days.Checked = false;
            rdo90Days.Checked = false;
            rdo180Days.Checked = false;
            rdo360Days.Checked = false;
        }

        private void btnQuery_Click(object sender, EventArgs e) { // 点击查询按钮时，尝试查询操作
            if (chkInDrugsDetails.Checked || chkOutDrugs.Checked || chkDestroyedDrugs.Checked) { // 当“记录类别”为“库存药品批次记录”或“已出库药品批次记录”或“已销毁药品批次记录”时
                // 不可同时查询“库存药品汇总”
                chkInDrugsSummary.Checked = false;
                chkInDrugsSummary.Enabled = false;
            }
            else {
                chkInDrugsSummary.Enabled = true;
            }
            if (chkInDrugsSummary.Checked) { // 当“记录类别”为“库存药品汇总”时
                // 不可同时查询其它类别的记录
                chkInDrugsDetails.Checked = false;
                chkInDrugsDetails.Enabled = false;
                chkOutDrugs.Checked = false;
                chkOutDrugs.Enabled = false;
                chkDestroyedDrugs.Checked = false;
                chkDestroyedDrugs.Enabled = false;
                // 查询条件中仅能包含“药品名称”
                cboSupplierId4.SelectedIndex = -1;
                cboSupplierId4.Text = "供应商名称";
                cboSupplierId4.Enabled = false;
                cboStaffId4.SelectedIndex = -1;
                cboStaffId4.Text = "负责职员";
                cboStaffId4.Enabled = false;
                cboDepartment_Handover4.SelectedIndex = -1;
                cboDepartment_Handover4.Text = "交接部门";
                cboDepartment_Handover4.Enabled = false;
                rdoAnyTime.Checked = false;
                rdoAnyTime.Enabled = false;
                rdo30Days.Checked = false;
                rdo30Days.Enabled = false;
                rdo90Days.Checked = false;
                rdo90Days.Enabled = false;
                rdo180Days.Checked = false;
                rdo180Days.Enabled = false;
                rdo360Days.Checked = false;
                rdo360Days.Enabled = false;
            }
            else {
                chkInDrugsDetails.Enabled = true;
                chkOutDrugs.Enabled = true;
                chkDestroyedDrugs.Enabled = true;
                cboSupplierId4.Enabled = true;
                cboStaffId4.Enabled = true;
                cboDepartment_Handover4.Enabled = true;
                rdoAnyTime.Enabled = true;
                rdo30Days.Enabled = true;
                rdo90Days.Enabled = true;
                rdo180Days.Enabled = true;
                rdo360Days.Enabled = true;
            }
            if (cboDepartment_Handover4.SelectedIndex != -1) { // 当查询条件中包含“交接部门”时
                // 仅能查询“已出库药品批次记录”
                chkInDrugsDetails.Checked = false;
                chkInDrugsSummary.Checked = false;
                chkDestroyedDrugs.Checked = false;
                chkInDrugsDetails.Enabled = false;
                chkInDrugsSummary.Enabled = false;
                chkDestroyedDrugs.Enabled = false;
            }
            else {
                chkInDrugsDetails.Enabled = true;
                chkInDrugsSummary.Enabled = true;
                chkDestroyedDrugs.Enabled = true;
            }
            string cmdText = string.Empty;
            SqlParameter[] parms = null;
            if (chkInDrugsSummary.Checked) {
                cmdText = "SELECT DrugName AS 药品名称, DrugNum AS 库存总数 FROM View_InDrugsSummary";
                parms = new SqlParameter[1];
                parms[0] = new SqlParameter("@DrugId", SqlDbType.UniqueIdentifier);
                if (cboDrugId4.SelectedIndex != -1) {
                    cmdText += " WHERE DrugId=@DrugId";
                    parms[0].Value = cboDrugId4.SelectedValue;
                }
                else {
                    parms[0].Value = Guid.Empty;
                }
            }
            else {
                if (chkInDrugsDetails.Checked && chkOutDrugs.Checked && chkDestroyedDrugs.Checked) { // 库存 + 已出库 + 已销毁
                    cmdText = "SELECT DrugName AS 药品名称, DrugBatch AS 批次, SupplierName AS 供应商, StaffName_In AS 入库职员, DrugInTime AS 入库时间, StaffName_Out AS 出库职员, DrugOutTime AS 出库时间, StaffName_Handover AS 交接职员, DepartmentName_Handover AS 交接部门, StaffName_Destroy AS 销毁职员, DrugDestroyTime AS 销毁时间, DrugNum AS 数量, RemainingLife AS '剩余保质期 (天数)' FROM View_AllRecordedDrugsDetails WHERE ";
                }
                else if (!chkInDrugsDetails.Checked && chkOutDrugs.Checked && chkDestroyedDrugs.Checked) { // 已出库 + 已销毁
                    cmdText = "SELECT DrugName AS 药品名称, DrugBatch AS 批次, SupplierName AS 供应商, StaffName_In AS 入库职员, DrugInTime AS 入库时间, StaffName_Out AS 出库职员, DrugOutTime AS 出库时间, StaffName_Handover AS 交接职员, DepartmentName_Handover AS 交接部门, StaffName_Destroy AS 销毁职员, DrugDestroyTime AS 销毁时间, DrugNum AS 数量 FROM View_AllRecordedDrugsDetails WHERE (StaffId_Out IS NOT NULL OR StaffId_Destroy IS NOT NULL) AND ";
                }
                else if (chkInDrugsDetails.Checked && !chkOutDrugs.Checked && chkDestroyedDrugs.Checked) { // 库存 + 已销毁
                    cmdText = "SELECT DrugName AS 药品名称, DrugBatch AS 批次, SupplierName AS 供应商, StaffName_In AS 入库职员, DrugInTime AS 入库时间, StaffName_Destroy AS 销毁职员, DrugDestroyTime AS 销毁时间, DrugNum AS 数量, RemainingLife AS '剩余保质期 (天数)' FROM View_AllRecordedDrugsDetails WHERE StaffId_Out IS NULL AND ";
                }
                else if (chkInDrugsDetails.Checked && chkOutDrugs.Checked && !chkDestroyedDrugs.Checked) { // 库存 + 已出库
                    cmdText = "SELECT DrugName AS 药品名称, DrugBatch AS 批次, SupplierName AS 供应商, StaffName_In AS 入库职员, DrugInTime AS 入库时间, StaffName_Out AS 出库职员, DrugOutTime AS 出库时间, StaffName_Handover AS 交接职员, DepartmentName_Handover AS 交接部门, DrugNum AS 数量, RemainingLife AS '剩余保质期 (天数)' FROM View_AllRecordedDrugsDetails WHERE StaffId_Destroy IS NULL AND ";
                }
                else if (!chkInDrugsDetails.Checked && !chkOutDrugs.Checked && chkDestroyedDrugs.Checked) { // 已销毁
                    cmdText = "SELECT DrugName AS 药品名称, DrugBatch AS 批次, SupplierName AS 供应商, StaffName_In AS 入库职员, DrugInTime AS 入库时间, StaffName_Destroy AS 销毁职员, DrugDestroyTime AS 销毁时间, DrugNum AS 数量 FROM View_AllRecordedDrugsDetails WHERE StaffId_Destroy IS NOT NULL AND ";
                }
                else if (!chkInDrugsDetails.Checked && chkOutDrugs.Checked && !chkDestroyedDrugs.Checked) { // 已出库
                    cmdText = "SELECT DrugName AS 药品名称, DrugBatch AS 批次, SupplierName AS 供应商, StaffName_In AS 入库职员, DrugInTime AS 入库时间, StaffName_Out AS 出库职员, DrugOutTime AS 出库时间, StaffName_Handover AS 交接职员, DepartmentName_Handover AS 交接部门, DrugNum AS 数量 FROM View_AllRecordedDrugsDetails WHERE StaffId_Out IS NOT NULL AND ";
                }
                else if (chkInDrugsDetails.Checked && !chkOutDrugs.Checked && !chkDestroyedDrugs.Checked) { // 库存
                    cmdText = "SELECT DrugName AS 药品名称, DrugBatch AS 批次, SupplierName AS 供应商, StaffName_In AS 入库职员, DrugInTime AS 入库时间, DrugNum AS 数量, RemainingLife AS '剩余保质期 (天数)' FROM View_AllRecordedDrugsDetails WHERE (StaffId_Out IS NULL AND StaffId_Destroy IS NULL) AND ";
                }
                else {
                    MessageBox.Show("至少选择一种记录类别才能查询出结果！", "请检查输入！");
                    return;
                }
                parms = new SqlParameter[5];
                parms[0] = new SqlParameter("@DrugId", SqlDbType.UniqueIdentifier);
                if (cboDrugId4.SelectedIndex != -1) {
                    parms[0].Value = cboDrugId4.SelectedValue;
                    cmdText += "DrugId=@DrugId AND ";
                }
                else {
                    parms[0].Value = Guid.Empty; // 不赋值会报错
                }
                parms[1] = new SqlParameter("@SupplierId", SqlDbType.UniqueIdentifier);
                if (cboSupplierId4.SelectedIndex != -1) {
                    parms[1].Value = cboSupplierId4.SelectedValue;
                    cmdText += "SupplierId=@SupplierId AND ";
                }
                else {
                    parms[1].Value = Guid.Empty; // 不赋值会报错
                }
                parms[2] = new SqlParameter("@StaffId", SqlDbType.UniqueIdentifier);
                if (cboStaffId4.SelectedIndex != -1) {
                    parms[2].Value = cboStaffId4.SelectedValue;
                    cmdText += "(StaffId_In=@StaffId OR StaffId_Out=@StaffId OR StaffId_Destroy=@StaffId) AND ";
                }
                else {
                    parms[2].Value = Guid.Empty; // 不赋值会报错
                }
                parms[3] = new SqlParameter("@DepartmentId_Handover", SqlDbType.UniqueIdentifier);
                if (cboDepartment_Handover4.SelectedIndex != -1) {
                    parms[3].Value = cboDepartment_Handover4.SelectedValue;
                    cmdText += "DepartmentId_Handover=@DepartmentId_Handover AND ";
                }
                else {
                    parms[3].Value = Guid.Empty; // 不赋值会报错
                }
                parms[4] = new SqlParameter("@DaysNum", SqlDbType.Int);
                if (rdoAnyTime.Checked || (!rdo30Days.Checked && !rdo90Days.Checked && !rdo180Days.Checked && !rdo360Days.Checked)) {
                    parms[4].Value = 0; // 不赋值会报错
                }
                else {
                    cmdText += "(DATEDIFF(DAY, DrugInTime, GETDATE()) <= @DaysNum OR DATEDIFF(DAY, DrugOutTime, GETDATE()) <= @DaysNum OR DATEDIFF(DAY, DrugDestroyTime, GETDATE()) <= @DaysNum) AND ";
                    if (rdo30Days.Checked) {
                        parms[4].Value = 30;
                    }
                    else if (rdo90Days.Checked) {
                        parms[4].Value = 90;
                    }
                    else if (rdo180Days.Checked) {
                        parms[4].Value = 180;
                    }
                    else if (rdo360Days.Checked) {
                        parms[4].Value = 360;
                    }
                }
                if (cmdText.LastIndexOf(" WHERE ") == cmdText.Length - 7) {
                    cmdText = cmdText.Remove(cmdText.Length - 7, 7);
                }
                else {
                    cmdText = cmdText.Remove(cmdText.Length - 5, 5);
                }
            }
            using (SqlConnection conn = new SqlConnection(connStr)) {
                SqlCommand cmd = new SqlCommand();
                cmd.CommandText = cmdText;
                cmd.Connection = conn;
                foreach (SqlParameter parm in parms) {
                    cmd.Parameters.Add(parm);
                }
                SqlDataAdapter da = new SqlDataAdapter();
                da.SelectCommand = cmd;
                DataTable dt = new DataTable();
                da.Fill(dt);
                dgvQuery.DataSource = dt;
            }
        }

        private void MainForm_FormClosing(object sender, FormClosingEventArgs e) { // 关闭窗体时，释放资源
            System.Environment.Exit(System.Environment.ExitCode);
            this.Dispose();
            this.Close();
        }
    }


    public class Staff { // 职员类
        private Guid id = Guid.Empty; // 标识字段
        private string no = string.Empty; // 编号字段
        private string name = string.Empty; // 姓名字段
        private string pwd = string.Empty; // 登录密码字段
        private Department dept; // 所属部门字段

        public Guid Id { // 标识属性
            get { return this.id; }
            set { this.id = value; }
        }

        public string No { // 编号属性
            get { return this.no; }
            set { this.no = value; }
        }

        public string Name { // 姓名属性
            get { return this.name; }
            set { this.name = value; }
        }

        public string Pwd { // 登录密码属性
            get { return this.pwd; }
            set { this.pwd = value; }
        }

        public Department Dept { // 所属部门属性
            get { return this.dept; }
            set { this.dept = value; }
        }

        public Staff(string no, string pwd) { // 构造函数
            this.No = no;
            this.Pwd = pwd;
        }

        public bool GetInfo() { // 尝试从数据库中获取该职员的相关信息
            string connStr = Properties.Settings.Default.DatabaseConnStr;
            SqlConnection conn = new SqlConnection(connStr);
            SqlCommand cmd = new SqlCommand();
            cmd.CommandText = "SELECT * FROM View_StaffsDetails WHERE StaffNo=@StaffNo AND StaffPwd=@StaffPwd";
            cmd.Connection = conn;
            SqlParameter[] parms = new SqlParameter[2];
            parms[0] = new SqlParameter("@StaffNo", SqlDbType.VarChar, 32);
            parms[0].Value = this.No;
            parms[1] = new SqlParameter("@StaffPwd", SqlDbType.VarChar, 32);
            parms[1].Value = this.Pwd;
            foreach (SqlParameter parm in parms) {
                cmd.Parameters.Add(parm);
            }
            SqlDataReader dr = null;
            try {
                conn.Open();
                dr = cmd.ExecuteReader();
                if (dr.Read()) {
                    this.Id = new Guid(dr["StaffId"].ToString());
                    this.Name = dr["StaffName"].ToString();
                    this.Dept = new Department(new Guid(dr["DepartmentId"].ToString()), dr["DepartmentName"].ToString());
                }
            }
            catch (Exception ex) {
                MessageBox.Show("出现异常：" + ex.Message, "请稍后重试！");
            }
            finally {
                if (dr != null && dr.IsClosed == false) {
                    dr.Close();
                }
                if (conn.State == ConnectionState.Open) {
                    conn.Close();
                }
            }
            if (this.Id == Guid.Empty) {
                return false;
            }
            else {
                return true;
            }
        }
    }


    public class Department { // 部门类
        private Guid id = Guid.Empty; // 标识字段
        private string name = string.Empty; // 名称字段

        public Guid Id { // 标识属性
            get { return this.id; }
            set { this.id = value; }
        }

        public string Name { // 名称属性
            get { return this.name; }
            set { this.name = value; }
        }

        public Department(Guid id, string name) { // 构造函数
            this.Id = id;
            this.Name = name;
        }
    }


    class MyException : Exception { // 自定义异常类
        public MyException(string message) : base(message) {
        }
    }
}
