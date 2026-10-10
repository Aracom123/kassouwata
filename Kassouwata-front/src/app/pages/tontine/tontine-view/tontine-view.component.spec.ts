import { ComponentFixture, TestBed } from '@angular/core/testing';

import { TontineViewComponent } from './tontine-view.component';

describe('TontineViewComponent', () => {
  let component: TontineViewComponent;
  let fixture: ComponentFixture<TontineViewComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [TontineViewComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(TontineViewComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
