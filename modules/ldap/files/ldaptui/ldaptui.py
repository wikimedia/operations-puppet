#! /usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
from time import sleep

import bituldap

from ldap3 import (
    Entry, Connection, ObjectDef, Reader)
from ldap3.core.exceptions import LDAPBindError
from passlib.hash import ldap_salted_sha1 as lsm
from textual import on
from textual.app import App
from textual.binding import Binding
from textual.coordinate import Coordinate
from textual.containers import Container, Horizontal, ScrollableContainer
from textual.screen import Screen
from textual.validation import Validator
from textual.widgets import (
    Button, DataTable, Footer, Header, Input, Label, Pretty)


config = bituldap.read_configuration()
success, conn = bituldap.create_connection()


TITLE = "LDAP UI Terminal UI"


def _user_definition(conn: Connection) -> ObjectDef:
    """Get object definition of LDAP3 query.
    The object definition will be used to map attributes onto the Entry objects.

    Args:
    conn (Connection): LDAP connection

    Returns:
    ObjectDef: Object definition for users, including auxiliary classes.
    """
    return ObjectDef(
        config.users.object_classes,
        conn,
        auxiliary_class=config.users.auxiliary_classes
    )


def search(query: str) -> None:
    """Search LDAP and return a reader object (iterable Entry objects.)

    Args:
    query (str): LDAP query
    escape_filter_chars (bool, optional): Whether or not to escape LDAP filter characters.
                                          Defaults to False.

    Returns:
    Reader: Read-Only iterable Entry objects.
    """
    success, conn = bituldap.create_connection()
    if not success:
        raise LDAPBindError()
    reader = Reader(conn, _user_definition(conn), config.users.dn, query)
    reader.search()
    return reader


class ActionScreen(Screen):
    success_message = "Success"

    async def auto_hide(self, lbl: Label, msg: str) -> None:
        for x in range(0, 5):
            lbl.update(f"{msg} ({5-x})")
            sleep(1)
        lbl.display = False

    def hide_action_status(self):
        self.query_one("#lbl_success", Label).display = False
        self.query_one("#lbl_error", Label).display = False

    def display_success(self):
        lbl: Label = self.query_one("#lbl_success", Label)
        if not lbl:
            return

        if not lbl.display:
            lbl.display = True
            self.run_worker(self.auto_hide(lbl, self.success_message), thread=True)

    def display_error(self, error: str):
        lbl = self.query_one("#lbl_error", Label)
        if not lbl.display:
            lbl.display = True
            self.run_worker(self.auto_hide(lbl, error), thread=True)

    @on(Button.Pressed, "#cancel")
    def cancel_pressed(self, event: Button.Pressed) -> None:
        self.screen.app.pop_screen()


class ListScreen(Screen):
    SUB_TITLE = "User list"

    def compose(self):
        with Container(classes="main", id="list") as container:  # noqa
            yield Header()
            yield DataTable(id="userlist", cursor_type="row")
            yield Footer()

    def key_enter(self) -> None:
        table = self.query_one(DataTable)
        coord = Coordinate(row=table.cursor_row, column=2)
        uid = table.get_cell_at(coord).value
        screen = EditUser(user=bituldap.get_user(uid))
        self.screen.app.push_screen(screen)

    def key_p(self) -> None:
        table = self.query_one(DataTable)
        coord = Coordinate(row=table.cursor_row, column=2)
        uid = table.get_cell_at(coord).value
        screen = PasswordScreen(user=bituldap.get_user(uid))
        self.screen.app.push_screen(screen)

    def populate_datatable(self, users: list[Entry]) -> None:
        headers = [("id", "CommonName", "UID", "E-Mail")]
        table = self.query_one(DataTable)
        table.clear()

        # Only load headers on first run.
        if not table.columns:
            table.add_columns(*headers[0])

        for user in users:
            table.add_row(user.uidNumber,
                          user.cn, user.uid,
                          user.mail if user.mail.value else ""
                          )

    def on_mount(self) -> None:
        users = [user for user in search("uid:*")]
        users.sort(key=lambda x: x.cn.value)
        self.populate_datatable(users)


class SearchScreen(ListScreen):
    SUB_TITLE = "User search"
    BINDINGS = [("p", "", "Change (p)assword")]

    def compose(self):
        with Container(classes="main", id="list") as container:  # noqa
            yield Header()
            yield Input(id="query", placeholder="search")
            yield DataTable(id="userlist", cursor_type="row")
            yield Footer()

    def on_input_changed(self, event: Input.Changed):
        query = self.query_one(Input)
        self.populate_datatable(
            search(f"uid:{query.value}*")
        )


class EditUser(ActionScreen):
    SUB_TITLE = "Edit user"
    success_message = "Successfully updated user"
    allows_fields = ["sn", "givenName", "mail", "manager", "uid", "loginShell", "homeDirectory"]

    def __init__(self, name=None, id=None, classes=None, user: Entry = None):
        self.user: Entry = user
        super().__init__(name, id, classes)

    def compose(self):
        with ScrollableContainer(classes="main", id="list") as container:  # noqa
            yield Header()
            yield Label(self.success_message, id="lbl_success", classes="lbl_success")
            yield Label("Error", id="lbl_error", classes="lbl_error")
            for k, v in self.user.entry_attributes_as_dict.items():
                if len(v) > 1 or k not in self.allows_fields:
                    continue
                if len(v) == 1:
                    value = v[0] if isinstance(v[0], str) else '?'
                else:
                    value = ''
                yield Label(k)
                yield Input(value, id=f"id_{k}")

            with Horizontal(classes="actions") as action:  # noqa
                yield Button(id="save", label="Save", variant="primary")
                yield Button("Cancel", id="cancel", variant="default")
            yield Footer()

    @on(Input.Changed)
    def attribute_changed(self, event: Input.Changed) -> None:
        attr_name = event.input.id[3:]
        if self.user:
            setattr(self.user, attr_name, event.input.value)

    @on(Button.Pressed, "#save")
    def save_pressed(self, event: Button.Pressed) -> None:
        if self.user.entry_commit_changes():
            self.display_success()
        else:
            self.display_error("Failed to update password")


class CreateScreen(ActionScreen):
    SUB_TITLE = "Create new user"

    def compose(self):
        with ScrollableContainer(classes="main", id="list") as container:  # noqa
            yield Header()
            yield Label(self.success_message, id="lbl_success", classes="lbl_success")
            yield Label("Error", id="lbl_error", classes="lbl_error")
            yield Label("CommonName")
            yield Input(id="id_cn", validators=[CommonNameValidator()])
            yield Label("UID - Unix user name")
            yield Input(id="id_uid", validators=[UIDValidator()])
            yield Label("Email")
            yield Input(id="id_mail", validators=(EmailValidator()))
            with Horizontal(classes="actions") as actions:  # noqa
                yield Button(id="save", label="Save", variant="primary")
                yield Button("Cancel", id="cancel", variant="default")
            yield Pretty([])
            yield Footer()

    @on(Button.Pressed, "#save")
    def save_pressed(self, event):
        uid = self.query_one("#id_uid", Input).value
        cn = self.query_one("#id_cn", Input).value
        mail = self.query_one("#id_mail", Input).value
        user = bituldap.new_user(uid)
        user.cn = cn
        user.givenName = cn
        user.sn = cn
        user.mail = mail
        user.uidNumber = bituldap.next_uid_number()
        user.gidNumber = 500
        user.homeDirectory = f"/home/{uid}"
        user.loginShell = "/bin/bash"
        user.sshPublicKey = ''
        user.wikimediaGlobalAccountName = ''
        if user.entry_commit_changes():
            self.display_success()
        else:
            self.display_error("Failed to create user")

    @on(Input.Changed)
    def show_invalid_reasons(self, event: Input.Changed) -> None:
        # Updating the UI to show the reasons why validation failed
        if not event.validation_result.is_valid:
            self.query_one(Pretty).update(event.validation_result.failure_descriptions)
        else:
            self.query_one(Pretty).update([])


class PasswordScreen(ActionScreen):
    SUB_TITLE = "Update password"
    success_message = "Successfully updated password"

    def __init__(self, name=None, id=None, classes=None, user: Entry = None):
        self.user = user
        super().__init__(name, id, classes)

    def compose(self):
        with Container(classes="main", id="list") as container:  # noqa
            yield Header()
            yield Label(self.success_message, id="lbl_success", classes="lbl_success")
            yield Label("Error", id="lbl_error", classes="lbl_error")
            yield Label(f"Update password for user: {self.user.cn} / {self.user.uid}")
            yield Label("Password")
            password1 = Input(id="password", password=True)
            yield password1
            yield Label("Password repeat")
            yield Input(id="password2", password=True,
                        validators=[PasswordValidator(password1=password1)])
            with Horizontal(classes="actions") as actions:  # noqa
                yield Button(id="save", label="Save", variant="primary", disabled=True)
                yield Button("Cancel", id="cancel", variant="default")
            yield Footer()

    @on(Input.Changed)
    def password_changed(self, event: Input.Changed) -> None:
        self.hide_action_status()

    @on(Input.Changed, "#password2")
    def password2_changed(self, event: Input.Changed) -> None:
        self.query_one("#save", Button).disabled = not event.validation_result.is_valid

    @on(Button.Pressed, "#save")
    def save_pressed(self, event: Button.Pressed) -> None:
        password2 = self.query_one("#password2")
        self.user.userPassword = lsm.hash(password2.value)
        if self.user.entry_commit_changes():
            self.display_success()
        else:
            self.display_error("Failed to update password")

    @on(Button.Pressed, "#cancel")
    def cancel_pressed(self, event: Button.Pressed) -> None:
        self.screen.pop_until_active()


class PasswordValidator(Validator):
    def __init__(self, failure_description=None, password1: Input = None):
        self.password1 = password1
        super().__init__(failure_description)

    def validate(self, value):
        if self.password1.value != value:
            return self.failure("Passwords did not match")
        return self.success()


class CommonNameValidator(Validator):
    def validate(self, value):
        if len(value) == 0 or value[0].islower():
            return self.failure("Common Name must start with a capital letter")

        try:
            user = bituldap.get_single_object(config.users, 'cn', value)
        except Exception as e:
            return self.failure(e)
        if user:
            return self.failure("Username exists")
        return self.success()


class UIDValidator(Validator):
    def validate(self, value):
        try:
            user = bituldap.get_user(value)
        except Exception as e:
            return self.failure(e)
        if user:
            return self.failure("Username exists")
        return self.success()


class EmailValidator(Validator):
    def validate(self, value):
        if "@" not in value or "." not in value:
            return self.failure("Invalid email")
        if value.endswith("@") or value.endswith("."):
            return self.failure("Invalid email")
        return self.success()


class CFLUIApp(App):
    TITLE = TITLE
    BINDINGS = (
        Binding("ctrl+q", action="quit", description="Quit", show=True),
        Binding("ctrl+n", action="push_screen('create')", description="New", show=True),
        Binding("ctrl+l", action="push_screen('search')", description="List", show=True)
    )

    CSS = """
    .main .input {
        margin-left: 1;
    }

    .main {
        margin-left: 1;
    }

    .lbl_success {
        border: double white;
        background: green;
        color: white;
        height: 3;
        width: 100%;
        align: center top;
        text-align: center;
        display: None;
    }

    .lbl_error {
        border: double white;
        background: red;
        color: white;
        height: 3;
        width: 100%;
        align: center top;
        text-align: center;
        display: None;
    }

    #userlist {
        border: double grey;
        width: 100%;
        margin-bottom: 4;
    }
    .actions {
        align: center bottom;
        width: 100%;
        margin: 1 1;
    }

    #save {
        margin-right: 2;
    }

    """

    SCREENS = {
        "create": CreateScreen,
        "list": ListScreen,
        "password": PasswordScreen,
        "search": SearchScreen,
    }

    def on_mount(self) -> None:
        self.theme = "textual-light"
        self.push_screen("search")


if __name__ == "__main__":
    app = CFLUIApp()
    app.run()
