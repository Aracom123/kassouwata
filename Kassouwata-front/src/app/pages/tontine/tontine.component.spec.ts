import { ComponentFixture, TestBed } from '@angular/core/testing';

import { TontineComponent } from './tontine.component';

describe('TontineComponent', () => {
  let component: TontineComponent;
  let fixture: ComponentFixture<TontineComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [TontineComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(TontineComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
